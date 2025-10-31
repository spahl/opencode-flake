# AGENTS.md - OpenCode & OpenSpec Nix Flake Development Guide

## Project Overview
This repository packages OpenCode (terminal-based AI assistant) and OpenSpec (spec-driven development tool) as Nix flakes. OpenCode 1.0.4+ uses pre-built binaries from GitHub releases. OpenSpec is built from source with all dependencies properly bundled. OpenSpec provides native integration with OpenCode through slash commands.

## Build/Test Commands
- `nix build` - Build the OpenCode package (default)
- `nix build .#openspec` - Build the OpenSpec package
- `nix flake check` - Run all flake checks (includes both package builds, versions, and structure tests)
- `nix run . -- --version` - Test the built OpenCode binary version
- `nix run .#openspec -- --version` - Test the built OpenSpec binary version
- `nix develop` - Enter development shell with both OpenCode and OpenSpec available
- `./scripts/test-workflow.sh` - Test the complete update workflow locally

## Version Updates

### Updating OpenCode Core (1.0.4+)
OpenCode 1.0.4+ uses pre-built binaries from GitHub releases. When updating:
1. Update `version` variable in package.nix (currently 1.0.4)
2. Download and compute hashes for all platforms:
   ```bash
   for file in opencode-linux-x64.zip opencode-linux-arm64.zip opencode-darwin-x64.zip opencode-darwin-arm64.zip; do
     curl -sL "https://github.com/sst/opencode/releases/download/v${VERSION}/$file" -o "$file"
     echo "$file: $(nix hash file --type sha256 --sri $file)"
     rm "$file"
   done
   ```
3. Update all four hashes in the `hashes` attribute set
4. Test with `nix build .#opencode && ./result/bin/opencode --version`

**Important Notes:**
- The binaries must NOT be stripped (`dontStrip = true`) as stripping corrupts the embedded version string
- Each platform (linux/darwin) and architecture (x64/arm64) has its own pre-built binary and hash
- The binary needs HOME set to run: `HOME=$(mktemp -d) opencode --version`

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

### OpenCode (package.nix) - Version 1.0.4+
The package uses pre-built binaries from GitHub releases:
1. Downloads platform-specific zip file from GitHub releases
2. Extracts the standalone binary (built with Bun's compile feature)
3. Applies autoPatchelfHook on Linux to fix dynamic library dependencies
4. The binary is a complete standalone executable containing:
   - TypeScript/JavaScript core
   - Native @opentui/core UI components
   - Native @parcel/watcher file watching
   - Tree-sitter parser worker

**Architecture Change:** OpenCode 1.0.4+ moved from separate Go TUI + TypeScript core to a single compiled binary built with Bun's compile feature. The official releases provide pre-built binaries for all platforms.

### OpenSpec (openspec.nix)
The package consists of two main derivations:
1. **node_modules**: OpenSpec dependencies (stdenvNoCC.mkDerivation with fixed-output)
2. **Main derivation**: Compiles TypeScript and creates standalone binary using bun

## Testing
- All changes must pass `nix flake check` before commit
- Use `scripts/update-version.sh` to automatically update all packages to their latest versions:
  - OpenCode (from release tags and pre-built binaries)
  - OpenSpec (from release tags)
  - opencode.nvim (from main branch latest commit)
- The update script handles hash updates for all packages and dependencies
- Test individual package builds:
  - `nix build .#opencode` - Test OpenCode
  - `nix run .#opencode -- --version` - Test OpenCode execution
  - `nix build .#openspec` - Test OpenSpec
  - `nix build .#opencode-nvim` - Test opencode.nvim

## Package Integration

### OpenCode & OpenSpec Integration
- OpenSpec has native OpenCode support through slash commands
- When `openspec init` runs, it creates commands in `.opencode/command/` directory
- Commands include: `openspec-proposal`, `openspec-apply`, `openspec-archive`
- Both packages can be used together or independently

### opencode.nvim Integration
- Neovim plugin for deep editor integration with OpenCode
- Provides commands, keybindings, and context injection from Neovim to OpenCode
- Can be installed via Nix in NixOS/home-manager configurations:
  ```nix
  programs.neovim.plugins = [ pkgs.opencode-nvim ];
  ```
- Or in nixvim:
  ```nix
  programs.nixvim.extraPlugins = [ pkgs.opencode-nvim ];
  ```

## Version Updates (continued)

### Updating opencode.nvim Plugin
When updating the opencode.nvim plugin in opencode-nvim.nix:
1. Get the latest commit SHA from main branch: `curl -s https://api.github.com/repos/NickvanDyke/opencode.nvim/commits/main | grep '"sha"'`
2. Get the commit date: `curl -s https://api.github.com/repos/NickvanDyke/opencode.nvim/commits/COMMIT_SHA | grep '"date"'`
3. Update `version = "main-YYYY-MM-DD"` with the commit date
4. Update `rev = "COMMIT_SHA"` with the new commit hash
5. Update `hash` - use `lib.fakeHash` initially, build will show correct hash
6. Build with `nix build .#opencode-nvim` to get the correct hash
7. Replace `lib.fakeHash` with the correct hash from build output

Note: Unlike OpenCode and OpenSpec which are TypeScript/Go applications compiled with bun, opencode.nvim is a pure Lua plugin that requires no compilation or dependencies.