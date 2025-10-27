# OpenCode & OpenSpec Integration Guide

This flake provides both OpenCode (AI coding assistant) and OpenSpec (spec-driven development tool) as integrated Nix packages.

## Quick Start

### Install Both Tools

```bash
# Install OpenCode
nix profile install github:aodhanhayter/opencode-flake

# Install OpenSpec
nix profile install github:aodhanhayter/opencode-flake#openspec
```

### Using Together

OpenSpec has native OpenCode integration through slash commands. Here's how to set it up:

1. **Initialize OpenSpec in your project:**
   ```bash
   cd your-project
   openspec init
   ```
   
   When prompted, select "OpenCode" from the list of AI tools.

2. **OpenSpec will create slash commands in `.opencode/command/`:**
   - `/openspec-proposal` - Create change proposals
   - `/openspec-apply` - Implement approved changes
   - `/openspec-archive` - Archive completed changes

3. **Start OpenCode and use the workflow:**
   ```bash
   opencode
   ```
   
   Then use natural language or the slash commands:
   ```
   /openspec-proposal Add user authentication with JWT
   ```

## Workflow Example

Here's a complete example of using OpenSpec with OpenCode:

### 1. Create a Proposal
```
You: /openspec-proposal Add profile search filters by role and team

AI:  Creates openspec/changes/add-profile-filters/ with:
     - proposal.md (why and what)
     - tasks.md (implementation checklist)
     - specs/*.md (requirement deltas)
```

### 2. Review and Refine
```
You: Can you add acceptance criteria for the team filters?

AI:  Updates the spec delta with detailed scenarios
```

### 3. Implement
```
You: /openspec-apply add-profile-filters

AI:  Implements tasks from the change proposal
     Marks tasks complete as work progresses
```

### 4. Archive
```
You: /openspec-archive add-profile-filters

AI:  Runs: openspec archive add-profile-filters --yes
     Merges spec deltas into main specs
     Moves change to archive/
```

## Benefits of Integration

1. **Structured Requirements**: Define what to build before writing code
2. **Change Tracking**: Every feature has its own change folder with proposal, tasks, and specs
3. **AI Guidance**: OpenCode follows the spec-driven workflow through slash commands
4. **Archival System**: Completed changes merge back into living documentation
5. **Cross-Tool Support**: OpenSpec works with many AI assistants, not just OpenCode

## Manual Commands

You can also run OpenSpec commands directly:

```bash
openspec list                    # View active changes
openspec view                    # Interactive dashboard
openspec show add-profile-filters  # View change details
openspec validate add-profile-filters  # Validate specs
openspec archive add-profile-filters --yes  # Archive manually
```

## Development Shell

Enter a shell with both tools available:

```bash
nix develop github:aodhanhayter/opencode-flake

# Now both commands are available:
opencode --version
openspec --version
```

## NixOS Configuration

Add both to your system or home-manager configuration:

```nix
{
  inputs.opencode-flake.url = "github:aodhanhayter/opencode-flake";

  # System packages:
  environment.systemPackages = [
    inputs.opencode-flake.packages.${pkgs.system}.opencode
    inputs.opencode-flake.packages.${pkgs.system}.openspec
  ];

  # Or home-manager:
  home.packages = [
    inputs.opencode-flake.packages.${pkgs.system}.opencode
    inputs.opencode-flake.packages.${pkgs.system}.openspec
  ];
}
```

## File Structure After Init

When you run `openspec init` with OpenCode selected, you'll get:

```
your-project/
├── .opencode/
│   └── command/
│       ├── openspec-proposal.md   (slash command)
│       ├── openspec-apply.md      (slash command)
│       └── openspec-archive.md    (slash command)
└── openspec/
    ├── AGENTS.md          (AI instructions)
    ├── project.md         (project context)
    ├── specs/             (main specifications)
    └── changes/           (active change proposals)
        └── archive/       (completed changes)
```

## References

- [OpenCode Repository](https://github.com/sst/opencode)
- [OpenSpec Repository](https://github.com/Fission-AI/OpenSpec)
- [OpenSpec Documentation](https://openspec.dev/)
