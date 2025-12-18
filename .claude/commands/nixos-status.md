---
description: "Get comprehensive NixOS system status"
---

You are providing a comprehensive status report of this NixOS system. Follow the NixOS assistant guidelines from `.claude/agents/nixos-assistant.md`.

Execute the following MCP tools in order and present a clear report:

1. **get_system_info** - Get basic system information
2. **get_flake_info** - Get flake metadata and inputs
3. **list_generations** - Show recent generations (limit to 5)
4. **list_installed_packages** - Show installed packages

Present the information in a well-formatted report with sections for:
- System Information (version, hostname, current system path)
- Flake Configuration (inputs, last modified)
- Recent Generations (for easy rollback reference)
- Package Summary (total count, highlight notable packages)

Make it concise and actionable.
