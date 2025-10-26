# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository packages [OpenCode](https://github.com/sst/opencode), a terminal-based AI assistant for developers, as a Nix flake. OpenCode is developed by SST (Serverless Stack) and this flake allows for easy installation and use in NixOS or other Nix-based environments.

## Development Environment

This project uses Nix flakes for dependency management and building:

```bash
# Check nix version
nix --version

# Show flake outputs
nix flake show

# Build the flake
nix build

# Develop with the flake
nix develop

# Run opencode
nix run . -- [args]

# Test version
nix run . -- --version
```

## Flake Structure

The main configuration is in `flake.nix`, which:
- Uses the unstable nixpkgs channel
- Uses flake-utils for multi-system support
- Downloads and packages pre-built binaries from npm
- Supports multiple platforms (aarch64-darwin, x86_64-darwin, aarch64-linux, x86_64-linux)

The flake implementation:
- Uses a custom `fetchNpmPackage` function to download tarballs from npm registry
- Includes a system-to-architecture mapping for platform-specific binaries
- Unpacks both the main package (`opencode-ai`) and platform-specific package
- Creates a proper FHS directory structure in the Nix store
- Uses `makeWrapper` to set environment variables for the binary
- Bundles the opencode-skills plugin (v0.1.0) into the compiled binary

The flake creates:
1. A package that can be installed in Nix environments
2. An app that can be run with `nix run`
3. A devShell for development

## Current Version

The flake currently packages OpenCode version 0.15.18 with opencode-skills plugin v0.1.0 bundled.

## Updating the Flake

To update the flake to a new version of OpenCode:
1. Update the `version` variable in `flake.nix`
2. Update the hashes in the `packageHashes` attribute set
   ```bash
   # Get correct hashes for each package
   nix-prefetch-url https://registry.npmjs.org/opencode-ai/-/opencode-ai-${version}.tgz
   nix-prefetch-url https://registry.npmjs.org/opencode-darwin-arm64/-/opencode-darwin-arm64-${version}.tgz
   nix-prefetch-url https://registry.npmjs.org/opencode-darwin-x64/-/opencode-darwin-x64-${version}.tgz
   nix-prefetch-url https://registry.npmjs.org/opencode-linux-arm64/-/opencode-linux-arm64-${version}.tgz
   nix-prefetch-url https://registry.npmjs.org/opencode-linux-x64/-/opencode-linux-x64-${version}.tgz
   
   # Convert hashes to SRI format (if needed)
   nix hash to-sri sha256:{hash}
   ```

## Installation

After building the flake, you can install OpenCode using:

```bash
# Install to your profile
nix profile install .

# Or add to your NixOS configuration
environment.systemPackages = [ inputs.opencode-flake.packages.${system}.default ];
```

## License

The project is licensed under the MIT License.