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

## Supported Systems

- aarch64-darwin (macOS on Apple Silicon)
- x86_64-darwin (macOS on Intel)
- aarch64-linux (Linux on ARM64)
- x86_64-linux (Linux on x86_64)

## Updating

### Automatic Update

The repository includes a script to automate version updates and CI workflows:

```bash
# Update to a new version
./update-version.sh 0.1.118

# Review and commit the changes
git diff
git commit -am "Update OpenCode flake to version 0.1.118"

# Tag the new version
./tag-version.sh
```

Additionally, a GitHub Actions workflow checks for new versions daily and automatically creates a PR when a new version is available.

### Manual Update

To manually update the flake to a new version of OpenCode:

1. Update the version variable in flake.nix
2. Update the hashes in the packageHashes attribute set in package.nix:

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

After updating, verify everything works:

```bash
# Make sure the package builds
nix build

# Run the checks to validate the updated package
nix flake check
```

## Version Tagging

To tag the current commit with the version from flake.nix:

```bash
# Tag the current commit
./tag-version.sh

# Tag a specific commit
./tag-version.sh abc123f

# Force overwrite an existing tag
./tag-version.sh --force
```

The tag will be created as `v{version}` (e.g., `v0.1.117`).

## CI/CD Workflows

This repository includes several GitHub Actions workflows:

1. **Check OpenCode Version** - Runs daily to check for new versions of OpenCode and automatically creates a PR when a new version is available.
2. **Test Nix Flake** - Runs on PRs and pushes to master to ensure the flake builds correctly on different platforms.
3. **Create Release** - Automatically creates a GitHub release when a new tag is pushed.

## License

This project is licensed under the MIT License - see the LICENSE file for details.