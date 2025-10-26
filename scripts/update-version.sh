#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Fetching latest OpenCode version from GitHub...${NC}"

LATEST_VERSION=$(curl -s https://api.github.com/repos/sst/opencode/releases/latest | jq -r '.tag_name' | sed 's/^v//')
echo -e "${GREEN}Latest OpenCode version: ${LATEST_VERSION}${NC}"

CURRENT_VERSION=$(grep -Po '(?<=^  version = ")[^"]+' package.nix | head -1)
echo -e "Current OpenCode version: ${CURRENT_VERSION}"

echo -e "${YELLOW}Fetching latest opencode-skills version from GitHub...${NC}"

LATEST_PLUGIN_VERSION=$(curl -s https://api.github.com/repos/malhashemi/opencode-skills/releases/latest | jq -r '.tag_name' | sed 's/^v//')
echo -e "${GREEN}Latest opencode-skills version: ${LATEST_PLUGIN_VERSION}${NC}"

CURRENT_PLUGIN_VERSION=$(grep -A 2 "opencode-skills-plugin" package.nix | grep -Po 'version = "\K[^"]+')
echo -e "Current opencode-skills version: ${CURRENT_PLUGIN_VERSION}"

NEEDS_UPDATE=false
if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo -e "${YELLOW}OpenCode needs update: ${CURRENT_VERSION} → ${LATEST_VERSION}${NC}"
    NEEDS_UPDATE=true
fi

if [ "$CURRENT_PLUGIN_VERSION" != "$LATEST_PLUGIN_VERSION" ]; then
    echo -e "${YELLOW}opencode-skills needs update: ${CURRENT_PLUGIN_VERSION} → ${LATEST_PLUGIN_VERSION}${NC}"
    NEEDS_UPDATE=true
fi

if [ "$NEEDS_UPDATE" = false ]; then
    echo -e "${GREEN}Already up to date!${NC}"
    exit 0
fi

echo -e "${YELLOW}Updating versions...${NC}"

# Update OpenCode if needed
if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo -e "${YELLOW}Fetching OpenCode source hash...${NC}"
    HASH_OLD=$(nix-prefetch-url --unpack "https://github.com/sst/opencode/archive/refs/tags/v${LATEST_VERSION}.tar.gz" 2>/dev/null)
    HASH_SRI=$(nix hash to-sri sha256:${HASH_OLD} 2>&1 | grep -Po 'sha256-\S+')
    echo -e "${GREEN}New OpenCode hash: ${HASH_SRI}${NC}"

    echo -e "${YELLOW}Updating OpenCode version in package.nix...${NC}"
    # Update the main version (first occurrence after 'pname = "opencode"')
    sed -i "0,/version = \".*\";/s//version = \"${LATEST_VERSION}\";/" package.nix
    # Update the hash in fetchFromGitHub for opencode
    sed -i "0,/hash = \"sha256-.*\";/s//hash = \"${HASH_SRI}\";/" package.nix
fi

# Update opencode-skills plugin if needed
if [ "$CURRENT_PLUGIN_VERSION" != "$LATEST_PLUGIN_VERSION" ]; then
    echo -e "${YELLOW}Fetching opencode-skills source hash...${NC}"
    PLUGIN_HASH_OLD=$(nix-prefetch-url --unpack "https://github.com/malhashemi/opencode-skills/archive/refs/tags/v${LATEST_PLUGIN_VERSION}.tar.gz" 2>/dev/null)
    PLUGIN_HASH_SRI=$(nix hash to-sri sha256:${PLUGIN_HASH_OLD} 2>&1 | grep -Po 'sha256-\S+')
    echo -e "${GREEN}New opencode-skills hash: ${PLUGIN_HASH_SRI}${NC}"

    echo -e "${YELLOW}Updating opencode-skills version in package.nix...${NC}"
    # Update opencode-skills version (in opencode-skills-plugin derivation)
    sed -i "/opencode-skills-plugin.*=/,/version = \".*\";/s/version = \".*\";/version = \"${LATEST_PLUGIN_VERSION}\";/" package.nix
    # Update the fetchurl url and hash for opencode-skills
    sed -i "s|https://github.com/malhashemi/opencode-skills/archive/refs/tags/v[^\"]*\.tar\.gz|https://github.com/malhashemi/opencode-skills/archive/refs/tags/v${LATEST_PLUGIN_VERSION}.tar.gz|" package.nix
    # Update the hash in the opencode-skills-plugin section (look for the second hash occurrence)
    awk -v new_hash="${PLUGIN_HASH_SRI}" '
        /opencode-skills-plugin/ {in_plugin=1}
        in_plugin && /hash = "sha256-[^"]*";/ && !updated {
            sub(/hash = "sha256-[^"]*";/, "hash = \"" new_hash "\";")
            updated=1
        }
        {print}
    ' package.nix > package.nix.tmp && mv package.nix.tmp package.nix
fi

echo -e "${YELLOW}Testing build (this may take a while)...${NC}"

# Function to handle hash mismatches
update_hash_from_error() {
    local log_file="/tmp/nix-build.log"
    if grep -q "got:" "$log_file"; then
        ERROR_LINE=$(grep "hash mismatch in fixed-output derivation" "$log_file" | tail -1)
        NEW_HASH=$(grep -Po "got:\s+\K\S+" "$log_file" | tail -1)
        
        if echo "$ERROR_LINE" | grep -q "go-modules"; then
            echo -e "${YELLOW}Updating vendorHash to: ${NEW_HASH}${NC}"
            sed -i "s|vendorHash = \".*\";|vendorHash = \"${NEW_HASH}\";|" package.nix
            return 0
        elif echo "$ERROR_LINE" | grep -q "opencode-skills"; then
            echo -e "${YELLOW}Updating opencode-skills outputHash to: ${NEW_HASH}${NC}"
            # Update the outputHash in opencode-skills-plugin derivation
            awk -v new_hash="${NEW_HASH}" '
                /opencode-skills-plugin/ {in_plugin=1}
                in_plugin && /outputHash = "sha256-[^"]*";/ && !updated {
                    sub(/outputHash = "sha256-[^"]*";/, "outputHash = \"" new_hash "\";")
                    updated=1
                    in_plugin=0
                }
                {print}
            ' package.nix > package.nix.tmp && mv package.nix.tmp package.nix
            return 0
        elif echo "$ERROR_LINE" | grep -q "node_modules"; then
            echo -e "${YELLOW}Updating node_modules outputHash to: ${NEW_HASH}${NC}"
            sed -i "s|x86_64-linux = \".*\";|x86_64-linux = \"${NEW_HASH}\";|" package.nix
            return 0
        fi
    fi
    return 1
}

# Try building up to 3 times to handle cascading hash updates
MAX_ATTEMPTS=3
for attempt in $(seq 1 $MAX_ATTEMPTS); do
    echo -e "${YELLOW}Build attempt ${attempt}/${MAX_ATTEMPTS}...${NC}"
    if nix build --no-link 2>&1 | tee /tmp/nix-build.log; then
        echo -e "${GREEN}Build succeeded!${NC}"
        break
    else
        if [ $attempt -eq $MAX_ATTEMPTS ]; then
            echo -e "${RED}Build failed after ${MAX_ATTEMPTS} attempts. Check /tmp/nix-build.log${NC}"
            exit 1
        fi
        
        if ! update_hash_from_error; then
            echo -e "${RED}Build failed for unknown reason. Check /tmp/nix-build.log${NC}"
            exit 1
        fi
    fi
done

echo -e "${YELLOW}Verifying version...${NC}"
BUILT_VERSION=$(nix run . -- --version 2>/dev/null | grep -v warning)
if [ "$BUILT_VERSION" = "$LATEST_VERSION" ]; then
    echo -e "${GREEN}✓ Version verified: ${BUILT_VERSION}${NC}"
else
    echo -e "${RED}✗ Version mismatch! Expected ${LATEST_VERSION}, got ${BUILT_VERSION}${NC}"
    exit 1
fi

echo -e "${YELLOW}Running flake checks...${NC}"
if nix flake check 2>&1 | grep -v warning; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
else
    echo -e "${RED}✗ Flake checks failed${NC}"
    exit 1
fi

echo -e "${GREEN}Successfully updated packages!${NC}"
if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo -e "${GREEN}  OpenCode: ${CURRENT_VERSION} → ${LATEST_VERSION}${NC}"
fi
if [ "$CURRENT_PLUGIN_VERSION" != "$LATEST_PLUGIN_VERSION" ]; then
    echo -e "${GREEN}  opencode-skills: ${CURRENT_PLUGIN_VERSION} → ${LATEST_PLUGIN_VERSION}${NC}"
fi

echo -e "${YELLOW}Don't forget to commit the changes:${NC}"
echo -e "  git add package.nix"
if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ] && [ "$CURRENT_PLUGIN_VERSION" != "$LATEST_PLUGIN_VERSION" ]; then
    echo -e "  git commit -m 'Update OpenCode to ${LATEST_VERSION} and opencode-skills to ${LATEST_PLUGIN_VERSION}'"
elif [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo -e "  git commit -m 'Update OpenCode to ${LATEST_VERSION}'"
else
    echo -e "  git commit -m 'Update opencode-skills to ${LATEST_PLUGIN_VERSION}'"
fi
