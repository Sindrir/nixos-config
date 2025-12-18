# NixOS MCP Server

An MCP (Model Context Protocol) server that provides NixOS system information to Claude.

## Features

- Search NixOS packages
- Get package information
- List installed packages
- Query system information
- Search NixOS options
- Get flake metadata
- List system generations
- Build configurations (dry-run)

## Usage

This server is designed to be used with Claude Code or other MCP-compatible clients.

Configure it in your MCP settings:

```json
{
  "mcpServers": {
    "nixos": {
      "command": "nixos-mcp-server"
    }
  }
}
```
