#!/bin/bash
set -eo pipefail

# Test script to verify the update workflow locally
echo "===== Testing OpenCode update workflow ====="

# Get current version from flake.nix
CURRENT_VERSION=$(grep -oP 'version = "\K[^"]+' flake.nix)
echo "Current version in flake.nix: $CURRENT_VERSION"

# Fetch latest version from npm
LATEST_VERSION=$(curl -s https://registry.npmjs.org/opencode-ai | jq -r '.["dist-tags"].latest')
echo "Latest version on npm: $LATEST_VERSION"

# If already up to date, simulate a new version for testing
if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
  echo "Already at latest version. Simulating a new version for testing..."
  # For testing, pretend there's a newer version by incrementing patch version
  IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
  VERSION_PARTS[2]=$((VERSION_PARTS[2] + 1))
  TEST_VERSION="${VERSION_PARTS[0]}.${VERSION_PARTS[1]}.${VERSION_PARTS[2]}"
  echo "Simulated new version: $TEST_VERSION"
  
  # Create a backup of flake.nix
  cp flake.nix flake.nix.bak
  
  # Run the check script in test mode
  echo "Running check-opencode-version.sh script..."
  export TEST_MODE=true
  export TEST_VERSION=$TEST_VERSION
  chmod +x ./scripts/check-opencode-version.sh
  if ./scripts/check-opencode-version.sh; then
    echo "✅ check-opencode-version.sh completed successfully"
  else
    echo "❌ check-opencode-version.sh failed"
    mv flake.nix.bak flake.nix
    exit 1
  fi
  
  # Check if flake.nix was updated
  NEW_VERSION=$(grep -oP 'version = "\K[^"]+' flake.nix)
  if [ "$NEW_VERSION" = "$TEST_VERSION" ]; then
    echo "✅ flake.nix was correctly updated to version $TEST_VERSION"
  else
    echo "❌ flake.nix update failed. Expected $TEST_VERSION, got $NEW_VERSION"
    mv flake.nix.bak flake.nix
    exit 1
  fi
  
  # Test if the flake builds
  echo "Testing flake build..."
  if nix build; then
    echo "✅ Flake builds successfully with the new version"
  else
    echo "❌ Flake build failed"
    mv flake.nix.bak flake.nix
    exit 1
  fi
  
  # Simulate the release script (without actually creating tags/releases)
  echo "Testing release script (simulation only)..."
  echo "Would create tag and release for version $TEST_VERSION"
  
  # Restore the backup
  echo "Restoring original flake.nix..."
  mv flake.nix.bak flake.nix
else
  # There's actually a newer version available
  echo "New version available: $LATEST_VERSION (current: $CURRENT_VERSION)"
  echo "To test the actual update, run ./scripts/check-opencode-version.sh"
fi

echo "===== Workflow test completed ====="