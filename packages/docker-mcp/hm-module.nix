{ config, lib, pkgs, ... }:

let
  cfg = config.programs.docker-mcp;
  docker-mcp-pkg = pkgs.callPackage ./default.nix { };

  # Pinned version — update default.nix to bump this
  installedVersion = "0.40.2";

  # Space-separated server names for the --servers flag
  serverList = lib.concatStringsSep "," cfg.servers;

in
{
  options.programs.docker-mcp = {
    enable = lib.mkEnableOption "Docker MCP Gateway CLI plugin";

    # ── Server list ───────────────────────────────────────────────────────────
    servers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "github-official" "atlassian" "context7" ];
      description = ''
        Names of MCP servers to enable.
        Run `docker mcp catalog show docker-mcp` to browse available servers.
      '';
    };

    # ── AI client integration ─────────────────────────────────────────────────
    claudeEnable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Add docker-mcp gateway as an MCP server to ~/.claude/settings.json.
        Claude Code will launch the gateway on demand via stdio.
      '';
    };

    # ── Update checking ───────────────────────────────────────────────────────
    checkUpdates = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Warn about new docker-mcp releases once per day in the Fish shell.";
    };
  };

  config = lib.mkIf cfg.enable {

    home = {
      # ── Install binary ──────────────────────────────────────────────────────
      packages = [ docker-mcp-pkg ];

      # Symlink into Docker CLI plugin directory so `docker mcp` works
      file.".docker/cli-plugins/docker-mcp" = {
        source = "${docker-mcp-pkg}/bin/docker-mcp";
      };

      activation = {
        # ── Enable servers ────────────────────────────────────────────────────
        # Persists the server selection in ~/.docker/mcp/ config files so that
        # a plain `docker mcp gateway run` (without --servers) also works.
        setupDockerMcpServers = lib.mkIf (cfg.servers != [ ])
          (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            echo "docker-mcp: enabling servers: ${lib.concatStringsSep ", " cfg.servers}"
            ${docker-mcp-pkg}/bin/docker-mcp server enable ${lib.concatStringsSep " " cfg.servers} || true
          '');

        # ── Claude Code MCP server entry ───────────────────────────────────────
        # Always writes the gateway entry so args (--servers, --secrets) stay
        # in sync with the Nix config after each home-manager switch.
        # Secrets file is created as a template on first run; populate it with
        # key=value pairs for each MCP server that requires credentials.
        setupClaudeMcpGateway = lib.mkIf cfg.claudeEnable
          (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                        _claude_settings="$HOME/.claude/settings.json"
                        _secrets_file="$HOME/.docker/mcp/secrets.env"

                        # Create secrets file template if it does not exist yet
                        if ! test -f "$_secrets_file"; then
                          mkdir -p "$(dirname "$_secrets_file")"
                          cat > "$_secrets_file" << 'SECRETS_TEMPLATE'
            # Docker MCP Gateway secrets — one KEY=value per line.
            # Examples:
            #   GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...
            #   ATLASSIAN_URL=https://yourorg.atlassian.net
            #   ATLASSIAN_USERNAME=you@example.com
            #   ATLASSIAN_API_TOKEN=...
            SECRETS_TEMPLATE
                          chmod 600 "$_secrets_file"
                        fi

                        if test -f "$_claude_settings"; then
                          echo "docker-mcp: updating gateway entry in Claude Code MCP servers"
                          ${pkgs.jq}/bin/jq \
                            --arg cmd "${docker-mcp-pkg}/bin/docker-mcp" \
                            --arg servers "${serverList}" \
                            --arg secrets "$_secrets_file" \
                            '. + {
                              mcpServers: ((.mcpServers // {}) + {
                                "docker-mcp": {
                                  "command": $cmd,
                                  "args": ["mcp", "gateway", "run",
                                           "--transport", "stdio",
                                           "--servers", $servers,
                                           "--secrets", $secrets]
                                }
                              })
                            }' "$_claude_settings" > "$_claude_settings.tmp" \
                          && mv "$_claude_settings.tmp" "$_claude_settings"
                        fi
          '');
      };
    };

    # ── Fish shell integration ────────────────────────────────────────────────
    programs.fish = {
      functions = lib.mkIf cfg.checkUpdates {
        check-docker-mcp-update = {
          description = "Warn once per day if a newer docker-mcp release is available";
          body = ''
            set -l cache_file ~/.cache/docker-mcp-version-check
            set -l interval 86400  # seconds in 24 h
            set -l installed "${installedVersion}"

            # Throttle: skip if cache is fresh
            if test -f $cache_file
              set -l last (cat $cache_file | string trim)
              set -l now (date +%s)
              if test (math $now - $last) -lt $interval
                return 0
              end
            end

            mkdir -p (dirname $cache_file)
            date +%s > $cache_file

            # Query GitHub releases API (requires curl + jq)
            set -l latest (
              curl -sf \
                -H "Accept: application/vnd.github+json" \
                "https://api.github.com/repos/docker/mcp-gateway/releases" \
              | jq -r '.[0].tag_name // empty' \
              | string replace -r '^v' ""
            )

            if test -z "$latest"
              return 0  # network unavailable — stay silent
            end

            if test "$latest" != "$installed"
              set_color yellow
              echo "⚠  docker-mcp update available: v$installed → v$latest"
              echo "   Update: https://github.com/docker/mcp-gateway/releases/tag/v$latest"
              echo "   Bump version in packages/docker-mcp/default.nix and run home-manager switch"
              set_color normal
            end
          '';
        };
      };

      # Run version check in background so it never delays the prompt
      interactiveShellInit = lib.mkIf cfg.checkUpdates ''
        check-docker-mcp-update &
      '';
    };
  };
}
