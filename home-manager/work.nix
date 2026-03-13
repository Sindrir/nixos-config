{ lib, pkgs, ... }:

{
  # ── GitHub MCP wrapper (GitHub App → installation token → github-mcp-server)
  home.file.".claude/github-mcp-wrapper.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      secrets_dir="''${HOME}/.config/sops-nix/secrets"
      GITHUB_APP_ID=$(cat "$secrets_dir/github_app_id")
      GITHUB_APP_INSTALLATION_ID=$(cat "$secrets_dir/github_app_installation_id")
      GITHUB_APP_PRIVATE_KEY_PATH="$secrets_dir/github_app_private_key"

      b64url() {
        ${pkgs.openssl}/bin/openssl base64 -e -A | tr '+/' '-_' | tr -d '='
      }

      now=$(date +%s)
      iat=$((now - 60))
      exp=$((now + 600))

      header=$(echo -n '{"alg":"RS256","typ":"JWT"}' | b64url)
      payload=$(printf '{"iss":"%s","iat":%d,"exp":%d}' "$GITHUB_APP_ID" "$iat" "$exp" | b64url)
      signature=$(printf '%s.%s' "$header" "$payload" | \
        ${pkgs.openssl}/bin/openssl dgst -sha256 -sign "$GITHUB_APP_PRIVATE_KEY_PATH" -binary | b64url)
      jwt="''${header}.''${payload}.''${signature}"

      response=$(${pkgs.curl}/bin/curl -sf -X POST \
        -H "Authorization: Bearer ''${jwt}" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/app/installations/''${GITHUB_APP_INSTALLATION_ID}/access_tokens")

      token=$(echo "$response" | grep -o '"token": *"[^"]*"' | head -1 | cut -d'"' -f4)
      if [[ -z "$token" ]]; then
        echo "Failed to get installation token" >&2
        exit 1
      fi

      export GITHUB_PERSONAL_ACCESS_TOKEN="$token"
      exec ${pkgs.github-mcp-server}/bin/github-mcp-server stdio
    '';
  };

  # ── Inject GitHub and Atlassian MCP servers into ~/.claude/settings.json ──
  home.activation.setupClaudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _claude_settings="$HOME/.claude/settings.json"
    if test -f "$_claude_settings"; then
      ${pkgs.jq}/bin/jq --arg wrapper "$HOME/.claude/github-mcp-wrapper.sh" '
        .mcpServers = ((.mcpServers // {}) + {
          "github": {
            "type": "stdio",
            "command": $wrapper
          },
          "atlassian": {
            "type": "http",
            "url": "https://mcp.atlassian.com/v1/mcp"
          }
        })
      ' "$_claude_settings" > "$_claude_settings.tmp" \
      && mv "$_claude_settings.tmp" "$_claude_settings"
    fi
  '';

  sops = {
    age.keyFile = "/home/sindreo/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets/github-app.yaml;
    secrets = {
      github_app_id = { };
      github_app_installation_id = { };
      github_app_private_key = { };
    };
  };

  # Slack development huddle - every Tuesday at 09:45
  systemd.user.services.slack-dev-huddle = {
    Unit.Description = "Join Slack development huddle";
    Service = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.libnotify}/bin/notify-send -a 'Slack' -i dialog-information -t 5000 'Development Huddle' 'Joining Slack huddle...'";
      ExecStart = "${pkgs.slack}/bin/slack 'slack://join-huddle?team=T0SNGK4R1&id=C0AENME6PGT'";
    };
  };
  systemd.user.timers.slack-dev-huddle = {
    Unit.Description = "Timer for Slack development huddle";
    Timer = {
      OnCalendar = "Tue *-*-* 09:45:00";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
