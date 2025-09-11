#!/usr/bin/env bash
# Script to update Go vendor hashes in package.nix
# This script is used by the GitHub workflow to handle vendorHash updates

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Attempting to update vendor hashes..."

# Function to extract hash from error message
extract_hash_from_error() {
    local error_output="$1"
    # Look for "got: sha256-..." pattern in the error
    echo "$error_output" | grep -oP 'got:\s+sha256-[A-Za-z0-9+/]+=*' | sed 's/got:\s*//'
}

# Function to update vendorHash in package.nix
update_vendor_hash() {
    local old_hash="$1"
    local new_hash="$2"
    
    echo -e "${YELLOW}Updating vendorHash from:${NC}"
    echo "  $old_hash"
    echo -e "${YELLOW}to:${NC}"
    echo "  $new_hash"
    
    # Update the vendorHash in package.nix
    sed -i "s|vendorHash = \"$old_hash\"|vendorHash = \"$new_hash\"|" package.nix
    
    if grep -q "$new_hash" package.nix; then
        echo -e "${GREEN}Successfully updated vendorHash${NC}"
        return 0
    else
        echo -e "${RED}Failed to update vendorHash${NC}"
        return 1
    fi
}

# Try to build and capture any hash mismatch errors
echo "Building package to check for hash mismatches..."
BUILD_OUTPUT=$(nix build .#opencode 2>&1) || BUILD_FAILED=$?

if [ "${BUILD_FAILED:-0}" -ne 0 ]; then
    # Check if it's a hash mismatch error
    if echo "$BUILD_OUTPUT" | grep -q "hash mismatch in fixed-output derivation"; then
        echo -e "${YELLOW}Hash mismatch detected, extracting correct hash...${NC}"
        
        # Extract the current hash from package.nix
        CURRENT_VENDOR_HASH=$(grep -oP 'vendorHash = "\K[^"]+' package.nix | head -1)
        
        # Extract the correct hash from error
        NEW_VENDOR_HASH=$(extract_hash_from_error "$BUILD_OUTPUT")
        
        if [ -n "$NEW_VENDOR_HASH" ]; then
            echo -e "${GREEN}Found correct vendorHash: $NEW_VENDOR_HASH${NC}"
            
            # Update the vendorHash
            if update_vendor_hash "$CURRENT_VENDOR_HASH" "$NEW_VENDOR_HASH"; then
                # Try building again with the new hash
                echo "Verifying build with new vendorHash..."
                if nix build .#opencode; then
                    echo -e "${GREEN}Build successful with updated vendorHash!${NC}"
                    exit 0
                else
                    echo -e "${RED}Build still failing after vendorHash update${NC}"
                    exit 1
                fi
            fi
        else
            echo -e "${RED}Could not extract correct hash from error output${NC}"
            echo "Error output:"
            echo "$BUILD_OUTPUT"
            exit 1
        fi
    else
        echo -e "${RED}Build failed but not due to hash mismatch${NC}"
        echo "$BUILD_OUTPUT"
        exit 1
    fi
else
    echo -e "${GREEN}Build successful, no hash updates needed${NC}"
    exit 0
fi