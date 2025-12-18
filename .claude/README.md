# Claude Configuration for nixos-config

This directory contains Claude Code customizations for this NixOS project.

## Quick Reference

### Slash Commands

- `/nixos` - General NixOS assistant with MCP tools
- `/nixos-status` - Get comprehensive system status
- `/nixos-search <query>` - Search packages/options
- `/nixos-install <package>` - Install package helper

### Files

- `agents/nixos-assistant.md` - NixOS assistant agent prompt
- `commands/*.md` - Slash command definitions
- `settings.local.json` - Local settings
- `NIXOS_AGENT.md` - Full documentation

## MCP Server

The NixOS assistant uses an MCP server that provides real-time system information:

**Location:** `packages/nixos-mcp-server/`
**Config:** `~/.config/claude-code/mcp.json`

### Available MCP Tools

1. search_packages
2. get_package_info
3. list_installed_packages
4. get_system_info
5. search_options
6. get_flake_info
7. list_generations
8. build_flake_config

## Getting Started

1. Rebuild home-manager to activate MCP server:
   ```bash
   home-manager switch --flake .#sindreo
   ```

2. Try a command:
   ```
   /nixos-status
   ```

3. Read full docs:
   ```
   cat .claude/NIXOS_AGENT.md
   ```

## How It Works

When you use a `/nixos*` command:
1. The command loads the NixOS assistant agent
2. The agent is configured to use MCP tools
3. It queries your actual system state
4. Provides accurate, system-specific advice

This means the assistant knows:
- Your NixOS version
- Your installed packages
- Your flake configuration
- Your system generations
- Available packages and options

All in real-time!
