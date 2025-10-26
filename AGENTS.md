# AGENTS.md - OpenCode Nix Flake Development Guide

## Project Overview
This repository packages OpenCode (terminal-based AI assistant) as a Nix flake, building from source with the opencode-skills plugin pre-bundled. The build creates a standalone binary with all dependencies embedded.

## Build/Test Commands
- `nix build` - Build the OpenCode package
- `nix flake check` - Run all flake checks (includes package build, version, binary, and library structure tests)
- `nix run . -- --version` - Test the built OpenCode binary version
- `nix develop` - Enter development shell with OpenCode available
- `./scripts/test-workflow.sh` - Test the complete update workflow locally

## Version Updates

### Updating OpenCode Core
When updating OpenCode version in package.nix:
1. Update `version` variable (currently 0.15.18)
2. Update git tag/hash in `fetchFromGitHub`
3. Update `vendorHash` for Go module in `tui` component if Go dependencies changed
4. Update `outputHash` for `node_modules` derivation (use placeholder first, let build fail to get correct hash)

### Updating opencode-skills Plugin
When updating the bundled plugin in package.nix:
1. Update `version` in `opencode-skills-plugin` derivation (currently 0.1.0)
2. Update source `url` and `hash` in `fetchurl`
3. Rebuild `opencode-skills-plugin` to get new `outputHash`
4. Rebuild `node_modules` to get new `outputHash` (since plugin is copied into it)
5. Verify plugin dependencies (gray-matter, zod) are in compiled binary with `strings result/bin/.opencode-wrapped | grep gray-matter`

## Code Style & Conventions
- **Language**: Nix expressions with functional programming style
- **Formatting**: 2-space indentation, align attributes vertically
- **Naming**: Use camelCase for variables, kebab-case for package names
- **Comments**: Use `#` for single-line comments, document complex logic
- **Imports**: Use `let...in` blocks for local bindings, inherit from inputs explicitly
- **Error Handling**: Use `throw` for unsupported systems, validate hashes exist
- **Version Management**: Keep OpenCode and plugin versions in sync in package.nix
- **Platform Support**: Maintain compatibility across aarch64/x86_64 for darwin/linux
- **Dependencies**: Use `nativeBuildInputs` for build-time deps, `buildInputs` for runtime
- **File Structure**: Keep package definition in `package.nix`, main flake config in `flake.nix`
- **Plugin Integration**: Plugins are built separately then copied into node_modules before OpenCode compilation

## Package Structure
The package consists of three main derivations in package.nix:
1. **tui**: Go-based terminal UI component (buildGoModule)
2. **opencode-skills-plugin**: TypeScript plugin compiled to JavaScript (stdenvNoCC.mkDerivation)
3. **node_modules**: OpenCode dependencies + bundled plugin (stdenvNoCC.mkDerivation with fixed-output)
4. **Main derivation**: Combines everything and compiles to standalone binary using bun

## Testing
- All changes must pass `nix flake check` before commit
- Use `scripts/update-version.sh` to automatically update OpenCode and opencode-skills to their latest versions
- The update script handles hash updates for both packages and all dependencies (go-modules, node_modules, plugin)