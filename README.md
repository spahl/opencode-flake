# OpenCode Nix Flake

This repository packages [OpenCode](https://github.com/sst/opencode), a terminal-based AI assistant for developers, as a Nix flake. OpenCode is developed by SST (Serverless Stack) and provides powerful AI-powered coding assistance directly in your terminal.

This flake automatically stays up-to-date with the latest OpenCode releases through automated workflows that run every 6 hours.

## Quick Start

```bash
# Run directly from the flake
nix run github:aodhanhayter/opencode-flake

# Check the version
nix run github:aodhanhayter/opencode-flake -- --version

# Install to your profile
nix profile install github:aodhanhayter/opencode-flake
```

## Installation

### Profile Installation
```bash
nix profile install github:aodhanhayter/opencode-flake
```

### NixOS/Home Manager Configuration
```nix
{
  inputs.opencode-flake.url = "github:aodhanhayter/opencode-flake";

  # In your configuration:
  environment.systemPackages = [ inputs.opencode-flake.packages.${pkgs.system}.default ];

  # Or in home-manager:
  home.packages = [ inputs.opencode-flake.packages.${pkgs.system}.default ];
}
```

## Packaging

This flake builds OpenCode from source, copying the approach from the official nixpkgs build. If you don't require the latest version of opencode, I recommend using the official nixpkgs version as it will likely be more stable and well tested.

- **Source-based builds**: Fetches source code directly from the [sst/opencode](https://github.com/sst/opencode) repository
- **Multi-component build system**:
  - **Go TUI Component**: Builds the terminal UI (`packages/tui`) using `buildGoModule`
  - **TypeScript Core**: Uses Bun to compile the main application logic
- **Bundled plugins**: Includes [opencode-skills](https://github.com/malhashemi/opencode-skills) plugin pre-installed
- **Deterministic builds**: Includes a local models patch to avoid network dependencies during build
- **Cross-platform support**: Supports all major platforms with proper platform-specific library linking

### Included Plugins

This package comes with the following plugins pre-installed:

- **[opencode-skills](https://github.com/malhashemi/opencode-skills)** (v0.1.0): Implements Anthropic's Agent Skills Specification, allowing you to define and use custom skills with OpenCode

To use the skills plugin, add it to your `opencode.json` or `~/.config/opencode/opencode.json`:

```json
{
  "plugin": ["opencode-skills"]
}
```

Then create skills in `.opencode/skills/`, `~/.opencode/skills/`, or `~/.config/opencode/skills/`. See the [opencode-skills documentation](https://github.com/malhashemi/opencode-skills#readme) for details.

## Development

```bash
# Enter development shell with OpenCode available
nix develop github:aodhanhayter/opencode-flake

# Build locally
nix build

# Test the package
nix flake check
```

## Automated Maintenance

This repository features **fully automated maintenance**:

- **Automatic updates**: GitHub Actions workflow runs every 6 hours using `nix-update`
- **Version detection**: Automatically detects new OpenCode releases from upstream
- **Auto-deployment**: Updates are automatically tested, tagged, and released
- **Zero-maintenance**: No manual intervention required for version updates

### Workflow Status

- Check the [workflow runs](https://github.com/AodhanHayter/opencode-flake/actions/workflows/update-opencode-nix.yml) to see recent updates
- **Note**: Scheduled workflows are automatically disabled after 60 days of repository inactivity
- To reactivate: Make any commit or [manually trigger the workflow](https://github.com/AodhanHayter/opencode-flake/actions/workflows/update-opencode-nix.yml)

### Manual Updates (if needed)

```bash
# Use the update script to automatically update OpenCode and opencode-skills
./scripts/update-version.sh

# Or manually with nix-update
nix-update --flake opencode

# Build and test
nix build && nix flake check
```

**Note**: The `update-version.sh` script automatically handles both OpenCode and opencode-skills plugin updates, including all necessary hash updates for dependencies. It will detect the latest versions from GitHub and update `package.nix` accordingly.

## Supported Systems

- `aarch64-darwin` (macOS on Apple Silicon)
- `x86_64-darwin` (macOS on Intel)
- `aarch64-linux` (Linux on ARM64)
- `x86_64-linux` (Linux on x86_64)

## Repository Structure

- `flake.nix`: Clean, minimal flake following nixpkgs patterns
- `package.nix`: Comprehensive OpenCode package definition with source builds
- `local-models-dev.patch`: Patch for deterministic builds with local models
- `.github/workflows/`: Automated CI/CD workflows

## CI/CD & Automation

### GitHub Actions Workflows

1. **Automated Updates** (`update-opencode-nix.yml`):
   - Runs every 6 hours (00:15, 06:15, 12:15, 18:15 UTC)
   - Uses `nix-update` for reliable version detection
   - Auto-creates releases and tags
   - Handles errors and cleanup automatically
   - Can be manually triggered via GitHub Actions UI

2. **Build Verification**:
   - Ensures packages build correctly across all platforms
   - Validates version reporting and functionality

## License

This project is licensed under the MIT License - see the LICENSE file for details.
