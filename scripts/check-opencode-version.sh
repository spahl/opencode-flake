#!/bin/bash
set -eo pipefail

# Script to check for new OpenCode versions on npm and update the flake.nix accordingly

# Function to get the current version from flake.nix
get_current_version() {
  if command -v ggrep &> /dev/null; then
    # Use GNU grep if available (via homebrew)
    ggrep -oP 'opencodeVersion = "\K[^"]+' flake.nix
  else
    # Fallback to sed for macOS compatibility
    sed -n 's/.*opencodeVersion = "\([^"]*\)".*/\1/p' flake.nix
  fi
}

# Function to get the latest version from npm
get_latest_version() {
  if [ "${TEST_MODE:-false}" = "true" ] && [ -n "$TEST_VERSION" ]; then
    echo "$TEST_VERSION"
  else
    curl -s https://registry.npmjs.org/opencode-ai | jq -r '.["dist-tags"].latest'
  fi
}

# Function to fetch a package hash
fetch_package_hash() {
  local package=$1
  local version=$2

  if [ "${TEST_MODE:-false}" = "true" ]; then
    # In test mode, return a fake hash
    if command -v sha256sum &> /dev/null; then
      echo "sha256-$(echo "$package-$version-test-hash" | sha256sum | cut -d ' ' -f 1 | xxd -r -p | base64)"
    else
      # Fallback for macOS
      echo "sha256-$(echo "$package-$version-test-hash" | shasum -a 256 | cut -d ' ' -f 1 | xxd -r -p | base64)"
    fi
    return
  fi

  local url="https://registry.npmjs.org/${package}/-/${package}-${version}.tgz"
  local hash
  hash=$(nix-prefetch-url "$url" 2>/dev/null)
  echo "sha256-$(nix hash convert --hash-algo sha256 --to base64 "$hash")"
}

# Function to update flake.nix with new version and hashes
update_flake() {
  local new_version=$1

  # Get hashes for all packages
  echo "Fetching hashes for OpenCode packages..."
  local main_hash=$(fetch_package_hash "opencode-ai" "$new_version")
  local darwin_arm64_hash=$(fetch_package_hash "opencode-darwin-arm64" "$new_version")
  local darwin_x64_hash=$(fetch_package_hash "opencode-darwin-x64" "$new_version")
  local linux_arm64_hash=$(fetch_package_hash "opencode-linux-arm64" "$new_version")
  local linux_x64_hash=$(fetch_package_hash "opencode-linux-x64" "$new_version")

  # Update version in flake.nix (macOS compatible)
  sed -i.bak "s/opencodeVersion = \"[^\"]*\"/opencodeVersion = \"$new_version\"/" flake.nix && rm flake.nix.bak

  # Update hashes in package.nix (macOS compatible)
  sed -i.bak "s|\"opencode-ai\" = \"[^\"]*\"|\"opencode-ai\" = \"$main_hash\"|" package.nix && rm package.nix.bak
  sed -i.bak "s|\"opencode-darwin-arm64\" = \"[^\"]*\"|\"opencode-darwin-arm64\" = \"$darwin_arm64_hash\"|" package.nix && rm package.nix.bak
  sed -i.bak "s|\"opencode-darwin-x64\" = \"[^\"]*\"|\"opencode-darwin-x64\" = \"$darwin_x64_hash\"|" package.nix && rm package.nix.bak
  sed -i.bak "s|\"opencode-linux-arm64\" = \"[^\"]*\"|\"opencode-linux-arm64\" = \"$linux_arm64_hash\"|" package.nix && rm package.nix.bak
  sed -i.bak "s|\"opencode-linux-x64\" = \"[^\"]*\"|\"opencode-linux-x64\" = \"$linux_x64_hash\"|" package.nix && rm package.nix.bak

  echo "Flake updated to version $new_version"
}

# Main script
current_version=$(get_current_version)
latest_version=$(get_latest_version)

echo "Current version: $current_version"
echo "Latest version: $latest_version"

if [ "$current_version" != "$latest_version" ]; then
  echo "Update needed! Updating from $current_version to $latest_version"
  update_flake "$latest_version"

  # Using modern GitHub Actions output syntax
  if [ -n "$GITHUB_OUTPUT" ]; then
    echo "updated=true" >> $GITHUB_OUTPUT
    echo "new_version=$latest_version" >> $GITHUB_OUTPUT
  else
    # Fallback for local testing and older GA runners
    echo "::set-output name=updated::true"
    echo "::set-output name=new_version::$latest_version"
  fi
else
  echo "Already at the latest version. No update needed."

  if [ -n "$GITHUB_OUTPUT" ]; then
    echo "updated=false" >> $GITHUB_OUTPUT
  else
    echo "::set-output name=updated::false"
  fi
fi
