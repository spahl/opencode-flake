# AGENTS.md - OpenCode Nix Flake Development Guide

## Project Overview
This repository packages OpenCode (terminal-based AI assistant) as a Nix flake, downloading pre-built binaries from npm registry and creating proper Nix store structure with platform-specific support.

## Build/Test Commands
- `nix build` - Build the OpenCode package
- `nix flake check` - Run all flake checks (includes package build, version, binary, and library structure tests)
- `nix run . -- --version` - Test the built OpenCode binary version
- `nix develop` - Enter development shell with OpenCode available
- `./scripts/test-workflow.sh` - Test the complete update workflow locally

## Version Updates
When updating OpenCode version:
1. Update `opencodeVersion` variable in flake.nix (currently 0.1.157) - this is the single source of truth
2. Update all hashes in `packageHashes` using `nix-prefetch-url` for each platform package
3. Convert hashes to SRI format with `nix hash to-sri sha256:{hash}`
4. Version checks automatically use the same `opencodeVersion` variable - no manual sync needed

## Code Style & Conventions
- **Language**: Nix expressions with functional programming style
- **Formatting**: 2-space indentation, align attributes vertically
- **Naming**: Use camelCase for variables, kebab-case for package names
- **Comments**: Use `#` for single-line comments, document complex logic
- **Imports**: Use `let...in` blocks for local bindings, inherit from inputs explicitly
- **Error Handling**: Use `throw` for unsupported systems, validate hashes exist
- **Version Management**: Update both `version` in flake.nix and `packageHashes` when upgrading
- **Platform Support**: Maintain compatibility across aarch64/x86_64 for darwin/linux
- **Dependencies**: Use `nativeBuildInputs` for build-time deps, `buildInputs` for runtime
- **File Structure**: Keep package definition in `package.nix`, main flake config in `flake.nix`

## Testing
- All changes must pass `nix flake check` before commit
- Version mismatches between flake.nix (line 37) and expected version (line 47) indicate update needed
- Use `scripts/test-workflow.sh` to simulate version updates locally