{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.claude-code.mcpServers;

  nixos-mcp-server = pkgs.callPackage ../packages/nixos-mcp-server { };

  mcpConfigFile = pkgs.writeText "claude_desktop_config.json" (builtins.toJSON {
    mcpServers = mapAttrs
      (name: server: {
        command = server.command;
        args = server.args;
        env = server.env;
      })
      cfg;
  });

in
{
  options.programs.claude-code.mcpServers = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        command = mkOption {
          type = types.str;
          description = "Command to run the MCP server";
        };

        args = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Arguments to pass to the MCP server";
        };

        env = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Environment variables for the MCP server";
        };
      };
    });
    default = { };
    description = "MCP servers configuration for Claude Code";
  };

  config = mkIf (cfg != { }) {
    home.packages = [ nixos-mcp-server ];

    # Create MCP configuration directory and file
    home.file.".config/claude-code/mcp.json" = {
      text = builtins.toJSON {
        mcpServers = mapAttrs
          (name: server: {
            command = server.command;
            args = server.args;
            env = server.env;
          })
          cfg;
      };
    };
  };
}
