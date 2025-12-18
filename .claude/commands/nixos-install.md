---
description: "Help install a package in NixOS configuration"
---

You are helping install a package in this NixOS system. Follow the NixOS assistant guidelines from `.claude/agents/nixos-assistant.md`.

Task: Help the user install the package(s) they specify.

Workflow:
1. Use **search_packages** to find the correct package name
2. Use **get_flake_info** to understand their configuration structure
3. Use **list_installed_packages** to check if it's already installed
4. Suggest adding it to the appropriate place in their configuration:
   - For system packages: hosts/*/configuration.nix
   - For user packages: home-manager/common.nix
5. Show the exact configuration change needed
6. Optionally offer to use **build_flake_config** to test

What package would you like to install?
