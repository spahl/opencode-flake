# AGENTS.md - OpenCode & OpenSpec Nix Flake Development Guide

## Project Overview
This repository packages OpenCode (terminal-based AI assistant) and OpenSpec (spec-driven development tool) as Nix flakes. Both are built from source with all dependencies properly bundled. OpenCode includes the opencode-skills plugin pre-bundled, and OpenSpec provides native integration with OpenCode through slash commands.

## Build/Test Commands
- `nix build` - Build the OpenCode package (default)
- `nix build .#openspec` - Build the OpenSpec package
- `nix flake check` - Run all flake checks (includes both package builds, versions, and structure tests)
- `nix run . -- --version` - Test the built OpenCode binary version
- `nix run .#openspec -- --version` - Test the built OpenSpec binary version
- `nix develop` - Enter development shell with both OpenCode and OpenSpec available
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
- **File Structure**: Keep package definitions in `package.nix` and `openspec.nix`, main flake config in `flake.nix`
- **Plugin Integration**: Plugins are built separately then copied into node_modules before OpenCode compilation
- **Multiple Packages**: Use separate derivations for each tool; OpenCode and OpenSpec are independent packages

## Package Structure

### OpenCode (package.nix)
The package consists of three main derivations:
1. **tui**: Go-based terminal UI component (buildGoModule)
2. **opencode-skills-plugin**: TypeScript plugin compiled to JavaScript (stdenvNoCC.mkDerivation)
3. **node_modules**: OpenCode dependencies + bundled plugin (stdenvNoCC.mkDerivation with fixed-output)
4. **Main derivation**: Combines everything and compiles to standalone binary using bun

### OpenSpec (openspec.nix)
The package consists of two main derivations:
1. **node_modules**: OpenSpec dependencies (stdenvNoCC.mkDerivation with fixed-output)
2. **Main derivation**: Compiles TypeScript and creates standalone binary using bun

## Testing
- All changes must pass `nix flake check` before commit
- Use `scripts/update-version.sh` to automatically update OpenCode and opencode-skills to their latest versions
- The update script handles hash updates for both packages and all dependencies (go-modules, node_modules, plugin)
- Test OpenSpec builds independently with `nix build .#openspec`

## OpenCode & OpenSpec Integration
- OpenSpec has native OpenCode support through slash commands
- When `openspec init` runs, it creates commands in `.opencode/command/` directory
- Commands include: `openspec-proposal`, `openspec-apply`, `openspec-archive`
- Both packages can be used together or independently