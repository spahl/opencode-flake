#!/usr/bin/env bash
set -euo pipefail

# Script to tag the current commit with the version from flake.nix
# Usage: ./tag-version.sh [--force] [commit]

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

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  error "Not in a git repository. Please run from the root of the OpenCode flake repository."
fi

# Check if we're at the repository root
if [[ ! -f "flake.nix" ]]; then
  error "flake.nix not found. Please run from the root of the OpenCode flake repository."
fi

# Parse arguments
force=false
commit="HEAD"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force|-f)
      force=true
      shift
      ;;
    *)
      commit="$1"
      shift
      ;;
  esac
done

# Function to extract version from flake.nix
extract_version() {
  # First try to extract using grep and sed
  local version
  version=$(grep -A 3 "opencodeVersion = " flake.nix | grep -o '"[0-9]\+\.[0-9]\+\.[0-9]\+"' | head -1 | tr -d '"')

  # If that didn't work, try using nix eval
  if [[ -z "$version" ]]; then
    info "Trying to extract version using nix evaluation..."
    if command -v nix >/dev/null 2>&1; then
      version=$(nix eval --raw --impure --expr "let flake = builtins.getFlake (toString ./.); in flake.packages.\"$(nix eval --impure --expr "builtins.currentSystem")\".default.version" 2>/dev/null || echo "")
    fi
  fi

  echo "$version"
}

# Extract version from flake.nix
info "Extracting version from flake.nix..."
version=$(extract_version)

if [[ -z "$version" ]]; then
  error "Could not extract version from flake.nix"
fi

info "Found version: $version"

# Validate version format
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  error "Invalid version format: $version (expected semver format like 0.1.117)"
fi

# Check if tag already exists
tag_name="v$version"
if git rev-parse "$tag_name" >/dev/null 2>&1; then
  if [[ "$force" == "true" ]]; then
    warn "Tag $tag_name already exists but --force flag was provided. Will overwrite."
    git tag -d "$tag_name" >/dev/null
  else
    error "Tag $tag_name already exists. Use --force to overwrite."
  fi
fi

# Get commit hash
commit_hash=$(git rev-parse "$commit")
if [[ $? -ne 0 ]]; then
  error "Invalid commit reference: $commit"
fi

# Check if the commit has uncommitted changes
if [[ "$commit" == "HEAD" ]] && ! git diff-index --quiet HEAD --; then
  warn "There are uncommitted changes in the working directory. Tagging anyway."
fi

# Create tag
info "Creating tag $tag_name for commit $commit_hash..."
git tag -a "$tag_name" "$commit_hash" -m "OpenCode flake version $version"

success "Successfully created tag $tag_name for commit $commit_hash"
info "To push this tag to the remote repository, run: git push origin $tag_name"

# Verify the flake builds with the tagged version
info "Verifying flake builds with the tagged version..."
if nix build .#packages."$(nix eval --impure --expr "builtins.currentSystem")".default --no-link >/dev/null 2>&1; then
  success "Flake builds successfully with the tagged version"
else
  warn "Could not verify flake build. You may want to check manually with 'nix build'"
fi

# Suggest next steps
cat << EOF

${BLUE}Next steps:${NC}
1. Push the tag to the remote repository:
   git push origin $tag_name

2. Create a GitHub release:
   gh release create $tag_name --title "OpenCode Flake $version" --notes "Release of OpenCode Flake version $version"

3. To update the version:
   - Edit version in flake.nix
   - Update hashes in package.nix
   - Run this script again
EOF
