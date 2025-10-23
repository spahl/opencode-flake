#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Fetching latest OpenCode version from GitHub...${NC}"

LATEST_VERSION=$(curl -s https://api.github.com/repos/sst/opencode/releases/latest | jq -r '.tag_name' | sed 's/^v//')
echo -e "${GREEN}Latest version: ${LATEST_VERSION}${NC}"

CURRENT_VERSION=$(grep -Po 'version = "\K[^"]+' package.nix)
echo -e "Current version: ${CURRENT_VERSION}"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo -e "${GREEN}Already up to date!${NC}"
    exit 0
fi

echo -e "${YELLOW}Updating from ${CURRENT_VERSION} to ${LATEST_VERSION}...${NC}"

echo -e "${YELLOW}Fetching source hash...${NC}"
HASH_OLD=$(nix-prefetch-url --unpack "https://github.com/sst/opencode/archive/refs/tags/v${LATEST_VERSION}.tar.gz" 2>/dev/null)
HASH_SRI=$(nix hash to-sri sha256:${HASH_OLD} 2>&1 | grep -Po 'sha256-\S+')
echo -e "${GREEN}New hash: ${HASH_SRI}${NC}"

echo -e "${YELLOW}Updating package.nix...${NC}"
sed -i "s/version = \".*\";/version = \"${LATEST_VERSION}\";/" package.nix
sed -i "s|hash = \"sha256-.*\";|hash = \"${HASH_SRI}\";|" package.nix

echo -e "${YELLOW}Testing build...${NC}"
if ! nix build --no-link 2>&1 | tee /tmp/nix-build.log; then
    if grep -q "got:" /tmp/nix-build.log; then
        NEW_VENDOR_HASH=$(grep -Po "got:\s+\K\S+" /tmp/nix-build.log | tail -1)
        echo -e "${YELLOW}Updating vendorHash to: ${NEW_VENDOR_HASH}${NC}"
        sed -i "s|vendorHash = \".*\";|vendorHash = \"${NEW_VENDOR_HASH}\";|" package.nix
        
        echo -e "${YELLOW}Rebuilding with new vendorHash...${NC}"
        nix build --no-link
    else
        echo -e "${RED}Build failed for unknown reason. Check /tmp/nix-build.log${NC}"
        exit 1
    fi
fi

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

echo -e "${GREEN}Successfully updated OpenCode to version ${LATEST_VERSION}!${NC}"
echo -e "${YELLOW}Don't forget to commit the changes:${NC}"
echo -e "  git add package.nix"
echo -e "  git commit -m '${LATEST_VERSION}'"
