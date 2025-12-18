# NixOS MCP Server Usage Guide

## Installation

The NixOS MCP server is already configured in your home-manager setup! To activate it:

```bash
# Rebuild your home-manager configuration
home-manager switch --flake .#sindreo

# Or rebuild your NixOS system (which includes home-manager)
sudo nixos-rebuild switch --flake .#home-desktop
```

## What it Does

The NixOS MCP server provides Claude with the ability to query and interact with your NixOS system:

### Available Tools

1. **search_packages** - Search for NixOS packages
   - Example: "Search for Firefox packages"

2. **get_package_info** - Get detailed information about a specific package
   - Example: "Get info about nixpkgs#firefox"

3. **list_installed_packages** - List packages installed in your profile
   - Example: "Show me my installed packages"

4. **get_system_info** - Get NixOS system information
   - Shows NixOS version, current system path, hostname

5. **search_options** - Search NixOS configuration options
   - Example: "Search for networking options"

6. **get_flake_info** - Get information about your flake configuration
   - Shows flake metadata, inputs, and outputs

7. **list_generations** - List system generations
   - Shows recent NixOS generations you can rollback to

8. **build_flake_config** - Test building a flake configuration (dry-run)
   - Example: "Dry-run build the home-desktop config"

### Available Resources

1. **nixos://system/configuration** - Current system configuration path
2. **nixos://system/generation** - Current generation information
3. **nixos://flake/metadata** - Flake metadata in JSON format

## Using with Claude Code

Once you've rebuilt your home-manager configuration, the MCP server will be automatically available to Claude Code.

You can ask Claude questions like:

- "What NixOS version am I running?"
- "Search for packages related to Python"
- "Show me my recent system generations"
- "What's in my flake inputs?"
- "List my installed packages"
- "Search for options related to services.nginx"

## Configuration

The MCP server configuration is stored in:
```
~/.config/claude-code/mcp.json
```

This file is managed by your home-manager configuration at:
```
home-manager/dotfiles/config/ai-agents/mcp.json
```

## Testing Manually

You can test the server manually:

```bash
# The server communicates via JSON-RPC over stdio
echo '{"jsonrpc":"2.0","id":1,"method":"ping"}' | nixos-mcp-server
```

## Troubleshooting

If the MCP server isn't showing up in Claude Code:

1. Make sure you've rebuilt your home-manager configuration
2. Restart Claude Code
3. Check that the mcp.json file exists: `cat ~/.config/claude-code/mcp.json`
4. Verify the server is in your PATH: `which nixos-mcp-server`

## Package Location

- Source: `/home/sindreo/nixos-config/packages/nixos-mcp-server/`
- Configuration: `/home/sindreo/nixos-config/home-manager/dotfiles/config/ai-agents/mcp.json`
- Home Manager integration: `/home/sindreo/nixos-config/home-manager/common.nix`
