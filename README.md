# OpenCode Nix Flake

This repository packages [OpenCode](https://github.com/sst/opencode), a terminal-based AI assistant for developers, as a Nix flake. The flake follows modern Nix practices, leveraging `flake-parts` for improved modularity.

## Usage

### Installation

```bash
# Install using flake reference
nix profile install github:aodhanhayter/opencode-flake

# Or add to your NixOS/home-manager configuration
{
  inputs.opencode-flake.url = "github:aodhanhayter/opencode-flake";
  # ...

  # In your configuration:
  environment.systemPackages = [ inputs.opencode-flake.packages.${pkgs.system}.default ];
}
```

### Running

```bash
# Run directly from the flake
nix run github:aodhanhayter/opencode-flake

# Check the version
nix run github:aodhanhayter/opencode-flake -- --version

# Enter development shell
nix develop github:aodhanhayter/opencode-flake
```

### Verification

The flake includes several checks to verify the OpenCode package works correctly:

```bash
# Run all checks
nix flake check

# Run individual checks
nix build .#checks.${system}.opencode-version
nix build .#checks.${system}.opencode-binary
nix build .#checks.${system}.opencode-library

# Run combined check
nix build .#checks.${system}.opencode-all-checks
```

Available checks:
- `opencode-package`: Builds the OpenCode package
- `opencode-version`: Verifies the correct version is reported
- `opencode-binary`: Checks the binary exists and is executable
- `opencode-library`: Validates the Node.js module structure
- `opencode-all-checks`: Runs all checks in sequence

## Flake Structure

This flake uses flake-parts for a modular structure:

- `flake.nix`: Entry point that defines inputs and outputs
- `package.nix`: Contains the OpenCode package definition
- `tag-version.sh`: Script for tagging git commits with version numbers
- `update-version.sh`: Script for updating to a new OpenCode version
- `.github/workflows/`: GitHub Actions workflows for CI/CD
- `scripts/`: Helper scripts for automation

## Supported Systems

- aarch64-darwin (macOS on Apple Silicon)
- x86_64-darwin (macOS on Intel)
- aarch64-linux (Linux on ARM64)
- x86_64-linux (Linux on x86_64)

## Updating

### Automatic Updates via GitHub Actions

This repository has automated workflows that keep the flake up-to-date with the latest OpenCode releases:

1. A GitHub Actions workflow checks for new OpenCode versions twice daily
2. When a new version is detected, it automatically:
   - Updates the flake.nix with the new version and package hashes
   - Creates a pull request with the changes
   - Tests that the updated flake builds correctly
   - Auto-merges the PR if all tests pass
   - Creates a GitHub release with the new version tag

You can also manually trigger this workflow from the Actions tab in the GitHub repository.

### Manual Updates

To manually update the flake to a new version of OpenCode:

1. Run the update script:
   ```bash
   # Use the automated script
   ./scripts/check-opencode-version.sh
   ```

2. Or update manually:
   ```bash
   # Update version in flake.nix
   # Update hashes using nix-prefetch-url
   nix-prefetch-url https://registry.npmjs.org/opencode-ai/-/opencode-ai-${version}.tgz
   # (Repeat for other packages)
   ```

3. Verify the update:
   ```bash
   # Test the flake builds correctly
   nix build
   ```

## Testing the Update Workflow

For testing the update workflow locally:

```bash
# Run the test workflow script
./scripts/test-workflow.sh
```

This script simulates what the GitHub Actions workflow will do, without creating actual releases.

## CI/CD Workflows

This repository includes several GitHub Actions workflows:

1. **Update OpenCode Version** - Runs twice daily to check for new versions of OpenCode and automatically creates PRs, tests, and releases.
2. **Test Flake** - Runs on PRs to ensure the flake builds correctly.
3. **Create Release** - Automatically creates a GitHub release when a new version is detected and merged.

## License

This project is licensed under the MIT License - see the LICENSE file for details.