#!/usr/bin/env bash
set -euo pipefail

# Script to update the OpenCode flake to a new version
# Usage: ./update-version.sh <new_version>

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print formatted messages
info() { echo -e "${BLUE}INFO:${NC} $1"; }
success() { echo -e "${GREEN}SUCCESS:${NC} $1"; }
warn() { echo -e "${YELLOW}WARNING:${NC} $1"; }
error() { echo -e "${RED}ERROR:${NC} $1"; exit 1; }

# Check arguments
if [[ $# -ne 1 ]]; then
  cat << EOF
Usage: ./update-version.sh <new_version>

Updates the OpenCode flake to a new version:
- Updates version in flake.nix
- Fetches new package hashes
- Updates hashes in package.nix

Example: ./update-version.sh 0.1.118
EOF
  exit 1
fi

# Validate new version format
new_version="$1"
if ! [[ "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  error "Invalid version format: $new_version (expected semver format like 0.1.117)"
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  error "Not in a git repository. Please run from the root of the OpenCode flake repository."
fi

# Check if we're at the repository root
if [[ ! -f "flake.nix" || ! -f "package.nix" ]]; then
  error "flake.nix or package.nix not found. Please run from the root of the OpenCode flake repository."
fi

# Function to extract current version from flake.nix
extract_current_version() {
  local version
  version=$(grep -A 3 "opencodeVersion = " flake.nix | grep -o '"[0-9]\+\.[0-9]\+\.[0-9]\+"' | head -1 | tr -d '"')
  echo "$version"
}

# Extract current version
current_version=$(extract_current_version)
if [[ -z "$current_version" ]]; then
  error "Could not extract current version from flake.nix"
fi

info "Current version: $current_version"
info "New version: $new_version"

# Check if the version is actually different
if [[ "$current_version" == "$new_version" ]]; then
  warn "New version is the same as current version. No changes needed."
  exit 0
fi

# Update version in flake.nix
info "Updating version in flake.nix..."
sed -i.bak "s/opencodeVersion = \"$current_version\"/opencodeVersion = \"$new_version\"/" flake.nix
rm flake.nix.bak

# Fetch new package hashes
info "Fetching hashes for new version..."

fetch_hash() {
  local package=$1
  local url="https://registry.npmjs.org/${package}/-/${package}-${new_version}.tgz"

  info "Fetching hash for $package v$new_version..." >&2
  if command -v nix-prefetch-url >/dev/null 2>&1; then
    hash=$(nix-prefetch-url "$url" 2>/dev/null)
    if [[ -n "$hash" ]]; then
      # Convert to SRI format
      if command -v nix >/dev/null 2>&1; then
        sri=$(nix hash to-sri --type sha256 "$hash" 2>/dev/null)
        if [[ -n "$sri" ]]; then
          echo "$sri"
          return 0
        fi
      fi
      # Fallback to raw hash
      echo "sha256-$hash"
      return 0
    fi
  fi

  # If nix-prefetch-url fails, inform user
  warn "Could not fetch hash for $package v$new_version" >&2
  warn "Please manually run: nix-prefetch-url $url" >&2
  echo ""
  return 1
}

# Fetch hashes for all packages
hash_main=$(fetch_hash "opencode-ai")
hash_darwin_arm64=$(fetch_hash "opencode-darwin-arm64")
hash_darwin_x64=$(fetch_hash "opencode-darwin-x64")
hash_linux_arm64=$(fetch_hash "opencode-linux-arm64")
hash_linux_x64=$(fetch_hash "opencode-linux-x64")

# Check if we have all hashes
if [[ -z "$hash_main" || -z "$hash_darwin_arm64" || -z "$hash_darwin_x64" || -z "$hash_linux_arm64" || -z "$hash_linux_x64" ]]; then
  error "Failed to fetch all required hashes. Please run the nix-prefetch-url commands manually and update package.nix accordingly."
fi

# Update hashes in package.nix
info "Updating hashes in package.nix..."

# Use awk instead of sed for more reliable hash replacement
awk -v main="$hash_main" \
    -v darwin_arm64="$hash_darwin_arm64" \
    -v darwin_x64="$hash_darwin_x64" \
    -v linux_arm64="$hash_linux_arm64" \
    -v linux_x64="$hash_linux_x64" '
{
    if (/^[[:space:]]*"opencode-ai" = ".*";/) {
        gsub(/"opencode-ai" = "[^"]*";/, "\"opencode-ai\" = \"" main "\";")
    } else if (/^[[:space:]]*"opencode-darwin-arm64" = ".*";/) {
        gsub(/"opencode-darwin-arm64" = "[^"]*";/, "\"opencode-darwin-arm64\" = \"" darwin_arm64 "\";")  
    } else if (/^[[:space:]]*"opencode-darwin-x64" = ".*";/) {
        gsub(/"opencode-darwin-x64" = "[^"]*";/, "\"opencode-darwin-x64\" = \"" darwin_x64 "\";")
    } else if (/^[[:space:]]*"opencode-linux-arm64" = ".*";/) {
        gsub(/"opencode-linux-arm64" = "[^"]*";/, "\"opencode-linux-arm64\" = \"" linux_arm64 "\";")
    } else if (/^[[:space:]]*"opencode-linux-x64" = ".*";/) {
        gsub(/"opencode-linux-x64" = "[^"]*";/, "\"opencode-linux-x64\" = \"" linux_x64 "\";")
    }
    print
}' "package.nix" > "package.nix.new"

# Verify changes and replace file
if cmp -s package.nix package.nix.new; then
  warn "No changes made to package.nix. Hash replacement may have failed."
  rm package.nix.new
else
  mv package.nix.new package.nix
  success "Updated hashes in package.nix"
fi

# Verify the flake builds with the new version
info "Verifying flake builds with the new version..."
if nix build .#packages."$(nix eval --impure --expr "builtins.currentSystem")".default --no-link; then
  success "Flake builds successfully with the new version"
else
  error "Flake fails to build with the new version. Please check for errors and fix them."
fi

# Suggest committing changes
cat << EOF

${GREEN}Version update completed successfully!${NC}

${BLUE}Next steps:${NC}
1. Review the changes:
   git diff

2. Commit the changes:
   git commit -am "Update OpenCode flake to version $new_version"

3. Tag the new version:
   ./tag-version.sh
EOF
