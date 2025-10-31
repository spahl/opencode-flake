#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Fetching latest OpenCode version from GitHub...${NC}"

LATEST_VERSION=$(curl -s https://api.github.com/repos/sst/opencode/releases/latest | jq -r '.tag_name' | sed 's/^v//')
echo -e "${GREEN}Latest OpenCode version: ${LATEST_VERSION}${NC}"

CURRENT_VERSION=$(grep -Po '(?<=version = ")[^"]+' package.nix | head -1)
echo -e "Current OpenCode version: ${CURRENT_VERSION}"

echo -e "${YELLOW}Fetching latest OpenSpec version from GitHub...${NC}"

LATEST_OPENSPEC_VERSION=$(curl -s https://api.github.com/repos/Fission-AI/OpenSpec/releases/latest | jq -r '.tag_name' | sed 's/^v//')
echo -e "${GREEN}Latest OpenSpec version: ${LATEST_OPENSPEC_VERSION}${NC}"

CURRENT_OPENSPEC_VERSION=$(grep -Po '(?<=version = ")[^"]+' openspec.nix | head -1)
echo -e "Current OpenSpec version: ${CURRENT_OPENSPEC_VERSION}"

echo -e "${YELLOW}Fetching latest opencode.nvim commit from GitHub...${NC}"

LATEST_NVIM_COMMIT=$(curl -s https://api.github.com/repos/NickvanDyke/opencode.nvim/commits/main | jq -r '.sha')
LATEST_NVIM_DATE=$(curl -s https://api.github.com/repos/NickvanDyke/opencode.nvim/commits/main | jq -r '.commit.committer.date' | cut -d'T' -f1)
LATEST_NVIM_VERSION="main-${LATEST_NVIM_DATE}"
echo -e "${GREEN}Latest opencode.nvim: ${LATEST_NVIM_VERSION} (${LATEST_NVIM_COMMIT:0:7})${NC}"

CURRENT_NVIM_VERSION=$(grep -Po '(?<=version = ")[^"]+' opencode-nvim.nix | head -1)
CURRENT_NVIM_COMMIT=$(grep -Po '(?<=rev = ")[^"]+' opencode-nvim.nix | head -1)
echo -e "Current opencode.nvim: ${CURRENT_NVIM_VERSION} (${CURRENT_NVIM_COMMIT:0:7})"

NEEDS_UPDATE=false
UPDATES=()

if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo -e "${YELLOW}OpenCode needs update: ${CURRENT_VERSION} → ${LATEST_VERSION}${NC}"
    NEEDS_UPDATE=true
    UPDATES+=("OpenCode to ${LATEST_VERSION}")
fi

if [ "$CURRENT_OPENSPEC_VERSION" != "$LATEST_OPENSPEC_VERSION" ]; then
    echo -e "${YELLOW}OpenSpec needs update: ${CURRENT_OPENSPEC_VERSION} → ${LATEST_OPENSPEC_VERSION}${NC}"
    NEEDS_UPDATE=true
    UPDATES+=("OpenSpec to ${LATEST_OPENSPEC_VERSION}")
fi

if [ "$CURRENT_NVIM_COMMIT" != "$LATEST_NVIM_COMMIT" ]; then
    echo -e "${YELLOW}opencode.nvim needs update: ${CURRENT_NVIM_VERSION} → ${LATEST_NVIM_VERSION}${NC}"
    NEEDS_UPDATE=true
    UPDATES+=("opencode.nvim to ${LATEST_NVIM_VERSION}")
fi

if [ "$NEEDS_UPDATE" = false ]; then
    echo -e "${GREEN}Already up to date!${NC}"
    exit 0
fi

echo -e "${YELLOW}Updating versions...${NC}"

# Update OpenCode if needed
if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ]; then
    echo -e "${YELLOW}Updating OpenCode to ${LATEST_VERSION}...${NC}"
    
    # Update version
    sed -i "0,/version = \".*\";/s||version = \"${LATEST_VERSION}\";|" package.nix
    
    # Download and compute hashes for all platforms
    echo -e "${YELLOW}Computing hashes for pre-built binaries...${NC}"
    
    PLATFORMS=("linux-x64" "linux-arm64" "darwin-x64" "darwin-arm64")
    declare -A HASHES
    
    for platform in "${PLATFORMS[@]}"; do
        echo -e "${YELLOW}  Downloading opencode-${platform}.zip...${NC}"
        curl -sL "https://github.com/sst/opencode/releases/download/v${LATEST_VERSION}/opencode-${platform}.zip" -o "/tmp/opencode-${platform}.zip"
        HASH=$(nix hash file --type sha256 --sri "/tmp/opencode-${platform}.zip")
        HASHES[$platform]=$HASH
        echo -e "${GREEN}  ${platform}: ${HASH}${NC}"
        rm "/tmp/opencode-${platform}.zip"
    done
    
    # Update hashes in package.nix
    echo -e "${YELLOW}Updating hashes in package.nix...${NC}"
    sed -i "s|\"x86_64-linux\" = \".*\";|\"x86_64-linux\" = \"${HASHES[linux-x64]}\";|" package.nix
    sed -i "s|\"aarch64-linux\" = \".*\";|\"aarch64-linux\" = \"${HASHES[linux-arm64]}\";|" package.nix
    sed -i "s|\"x86_64-darwin\" = \".*\";|\"x86_64-darwin\" = \"${HASHES[darwin-x64]}\";|" package.nix
    sed -i "s|\"aarch64-darwin\" = \".*\";|\"aarch64-darwin\" = \"${HASHES[darwin-arm64]}\";|" package.nix
fi

# Update OpenSpec if needed
if [ "$CURRENT_OPENSPEC_VERSION" != "$LATEST_OPENSPEC_VERSION" ]; then
    echo -e "${YELLOW}Fetching OpenSpec source hash...${NC}"
    OPENSPEC_HASH_OLD=$(nix-prefetch-url --unpack "https://github.com/Fission-AI/OpenSpec/archive/refs/tags/v${LATEST_OPENSPEC_VERSION}.tar.gz" 2>/dev/null)
    OPENSPEC_HASH_SRI=$(nix hash to-sri sha256:${OPENSPEC_HASH_OLD} 2>&1 | grep -Po 'sha256-\S+')
    echo -e "${GREEN}New OpenSpec hash: ${OPENSPEC_HASH_SRI}${NC}"

    echo -e "${YELLOW}Updating OpenSpec version in openspec.nix...${NC}"
    sed -i "0,/version = \".*\";/s||version = \"${LATEST_OPENSPEC_VERSION}\";|" openspec.nix
    sed -i "0,/hash = \"sha256-.*\";/s||hash = \"${OPENSPEC_HASH_SRI}\";|" openspec.nix
fi

# Update opencode.nvim if needed
if [ "$CURRENT_NVIM_COMMIT" != "$LATEST_NVIM_COMMIT" ]; then
    echo -e "${YELLOW}Fetching opencode.nvim source hash...${NC}"
    NVIM_HASH_OLD=$(nix-prefetch-url --unpack "https://github.com/NickvanDyke/opencode.nvim/archive/${LATEST_NVIM_COMMIT}.tar.gz" 2>/dev/null)
    NVIM_HASH_SRI=$(nix hash to-sri sha256:${NVIM_HASH_OLD} 2>&1 | grep -Po 'sha256-\S+')
    echo -e "${GREEN}New opencode.nvim hash: ${NVIM_HASH_SRI}${NC}"

    echo -e "${YELLOW}Updating opencode.nvim in opencode-nvim.nix...${NC}"
    sed -i "0,/version = \".*\";/s||version = \"${LATEST_NVIM_VERSION}\";|" opencode-nvim.nix
    sed -i "0,/rev = \".*\";/s||rev = \"${LATEST_NVIM_COMMIT}\";|" opencode-nvim.nix
    sed -i "0,/hash = \"sha256-.*\";/s||hash = \"${NVIM_HASH_SRI}\";|" opencode-nvim.nix
fi

echo -e "${YELLOW}Testing build (this may take a while)...${NC}"

# Function to update node_modules hash from build error
update_openspec_hash() {
    local log_file="/tmp/nix-build.log"
    if grep -q "got:" "$log_file"; then
        NEW_HASH=$(grep -Po "got:\s+\K\S+" "$log_file" | tail -1)
        echo -e "${YELLOW}Updating OpenSpec node_modules hash to: ${NEW_HASH}${NC}"
        sed -i "s|x86_64-linux = \"sha256-.*\";|x86_64-linux = \"${NEW_HASH}\";|" openspec.nix
        return 0
    fi
    return 1
}

# Try building up to 3 times to handle hash updates
MAX_ATTEMPTS=3
for attempt in $(seq 1 $MAX_ATTEMPTS); do
    echo -e "${YELLOW}Build attempt ${attempt}/${MAX_ATTEMPTS}...${NC}"
    
    if nix flake check 2>&1 | tee /tmp/nix-build.log; then
        echo -e "${GREEN}Build successful!${NC}"
        break
    else
        if [ $attempt -lt $MAX_ATTEMPTS ] && grep -q "hash mismatch" /tmp/nix-build.log; then
            echo -e "${YELLOW}Hash mismatch detected, updating...${NC}"
            if ! update_openspec_hash; then
                echo -e "${RED}Failed to update hash${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Build failed${NC}"
            cat /tmp/nix-build.log
            exit 1
        fi
    fi
done

echo -e "${GREEN}✓ Successfully updated:${NC}"
for update in "${UPDATES[@]}"; do
    echo -e "${GREEN}  - ${update}${NC}"
done

echo -e "${YELLOW}Run 'git diff' to review changes${NC}"
