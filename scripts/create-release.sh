#!/bin/bash
set -eo pipefail

# Script to create a GitHub release for a new OpenCode version

if [ $# -ne 1 ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

VERSION=$1
RELEASE_TAG="v$VERSION"

# Check if tag already exists
if git rev-parse "$RELEASE_TAG" >/dev/null 2>&1; then
  echo "Tag $RELEASE_TAG already exists. Skipping release creation."
  exit 0
fi

# Create and push tag
git tag -a "$RELEASE_TAG" -m "OpenCode version $VERSION"
git push origin "$RELEASE_TAG"

# Create GitHub release
gh release create "$RELEASE_TAG" \
  --title "OpenCode v$VERSION" \
  --notes "This release updates the OpenCode flake to version $VERSION.

Automated release created by GitHub Actions." \
  --repo "$GITHUB_REPOSITORY"

echo "Created GitHub release for OpenCode v$VERSION"