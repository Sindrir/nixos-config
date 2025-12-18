# NixOS Assistant Agent Documentation

## Overview

This project includes a specialized NixOS assistant agent that has real-time access to your NixOS system through MCP (Model Context Protocol) tools. The agent is designed to provide accurate, system-specific advice by querying your actual system state.

## Quick Start

### Activate the Agent

Use any of these slash commands in Claude Code:

```
/nixos              # General NixOS assistance
/nixos-status       # Get comprehensive system status
/nixos-search       # Search for packages or options
/nixos-install      # Help install a package
```

## Available Slash Commands

### `/nixos` - General NixOS Assistant

Activates the NixOS assistant for any NixOS-related task. The agent will:
- Check your system state with MCP tools
- Provide context-aware recommendations
- Help with configuration changes

**Example usage:**
```
/nixos how do I enable docker?
/nixos help me configure my firewall
/nixos what's the best way to manage Python packages?
```

### `/nixos-status` - System Status Report

Generates a comprehensive status report including:
- NixOS version and system info
- Flake metadata and inputs
- Recent generations (for rollback)
- Installed packages summary

**Example usage:**
```
/nixos-status
```

### `/nixos-search` - Search Packages & Options

Search for packages in nixpkgs or NixOS configuration options.

**Example usage:**
```
/nixos-search docker
/nixos-search services.nginx
/nixos-search python packages
```

### `/nixos-install` - Install Package Assistant

Guided workflow to install a new package:
1. Searches for the package
2. Checks if already installed
3. Suggests where to add it in your config
4. Shows exact configuration needed

**Example usage:**
```
/nixos-install firefox
/nixos-install htop
```

## How the Agent Works

### MCP Tools Available

The agent has access to 8 MCP tools that query your real system:

| Tool | Purpose |
|------|---------|
| `search_packages` | Search nixpkgs for packages |
| `get_package_info` | Get details about a specific package |
| `list_installed_packages` | List currently installed packages |
| `get_system_info` | Get NixOS version, hostname, etc. |
| `search_options` | Search NixOS configuration options |
| `get_flake_info` | Get flake metadata and inputs |
| `list_generations` | List system generations |
| `build_flake_config` | Dry-run build configurations |

### Agent Behavior

The NixOS assistant is configured to:

1. **Query First**: Always check actual system state before making recommendations
2. **Be Specific**: Use real package names and paths from your system
3. **Show Config Changes**: Demonstrate exactly where to make changes in your flake
4. **Suggest Testing**: Offer dry-run builds before actual changes
5. **Follow Best Practices**: Emphasize declarative, reproducible configurations

## Example Workflows

### Installing a New Package

```
You: /nixos-install docker
Agent:
  1. [Uses search_packages to find docker]
  2. [Uses list_installed_packages to check if installed]
  3. Found: nixpkgs#docker
  4. Not currently installed
  5. Suggests adding to home-manager/common.nix:

     home.packages = with pkgs; [
       ...
       docker
     ];

  6. Offers to test with build_flake_config
```

### Checking System State

```
You: /nixos-status
Agent:
  [Queries multiple MCP tools]

  System Information:
  - NixOS Version: 24.11
  - Hostname: home-desktop
  - Current System: /nix/store/...

  Flake Configuration:
  - Path: /home/sindreo/nixos-config
  - Inputs: nixpkgs, home-manager, nvf, wezterm
  - Last Modified: 2025-11-28

  Recent Generations:
  - Generation 142 (current)
  - Generation 141 (1 day ago)
  ...

  Packages: 143 installed
```

### Configuration Help

```
You: /nixos how do I enable SSH?
Agent:
  1. [Uses search_options for "ssh"]
  2. Found option: services.openssh.enable
  3. Add to hosts/home-desktop/configuration.nix:

     services.openssh = {
       enable = true;
       settings = {
         PermitRootLogin = "no";
         PasswordAuthentication = false;
       };
     };

  4. Then rebuild: sudo nixos-rebuild switch --flake .#home-desktop
```

## Tips for Best Results

1. **Be Specific**: The agent works best with specific questions
   - Good: "How do I install Firefox?"
   - Better: "How do I install Firefox and make it my default browser?"

2. **Use the Right Command**: Choose the appropriate slash command
   - Quick status? Use `/nixos-status`
   - Installing something? Use `/nixos-install`
   - General help? Use `/nixos`

3. **Trust the MCP Data**: The agent queries your actual system, so its recommendations are system-specific

4. **Ask Follow-ups**: The agent maintains context, so you can ask clarifying questions

## Project Structure Context

The agent knows about your project structure:

```
nixos-config/
├── flake.nix              # Main flake configuration
├── home-manager/
│   ├── sindreo.nix        # Your user config
│   └── common.nix         # Common home-manager config
├── hosts/
│   ├── home-desktop/      # Desktop configuration
│   └── work-laptop/       # Laptop configuration
├── modules/               # NixOS modules
│   ├── de/               # Desktop environments
│   └── ...
└── packages/             # Custom packages
    └── nixos-mcp-server/ # The MCP server itself
```

## Troubleshooting

### Agent not using MCP tools?

Make sure you've:
1. Rebuilt your home-manager: `home-manager switch --flake .#sindreo`
2. Restarted Claude Code
3. Verified MCP config exists: `cat ~/.config/claude-code/mcp.json`

### Slash commands not showing up?

The commands are defined in `.claude/commands/`. Make sure:
1. The files exist in the project directory
2. You're running Claude Code from the nixos-config directory
3. You've reloaded Claude Code

### Want to customize the agent?

Edit these files:
- Agent behavior: `.claude/agents/nixos-assistant.md`
- Slash commands: `.claude/commands/nixos*.md`

## Advanced Usage

### Creating Custom Commands

You can create your own slash commands in `.claude/commands/`:

```markdown
---
description: "Your command description"
---

Your command prompt here, which can reference
the NixOS assistant agent and use MCP tools.
```

### Extending the Agent

Edit `.claude/agents/nixos-assistant.md` to:
- Add more specific knowledge about your setup
- Customize the agent's tone or style
- Add more workflow patterns
- Include project-specific conventions

## What's Next?

Try these commands to get started:

1. `/nixos-status` - See your current system state
2. `/nixos-search vim` - Search for vim-related packages
3. `/nixos` - Ask any NixOS question!

The agent is configured to be proactive with MCP tools, so it will automatically query your system to give you accurate, personalized help.
