{ config, lib, pkgs, ... }:

let
  cfg = config.programs.claude-code-settings;
  # Only plugins set to true need to be installed
  pluginsToInstall = lib.attrNames (lib.filterAttrs (_: v: v) cfg.plugins);
  # Marketplaces we can auto-register via `claude plugin marketplace add`
  # (needs a github owner/repo; anything else has to be added by hand)
  marketplacesToAdd = lib.filterAttrs
    (_: m: ((m.source or { }).source or null) == "github" && ((m.source or { }).repo or null) != null)
    cfg.marketplaces;
in
{
  options.programs.claude-code-settings = {
    enable = lib.mkEnableOption "Declarative Claude Code settings management";

    marketplaces = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = ''
        Extra plugin marketplaces merged into `extraKnownMarketplaces` in
        ~/.claude/settings.json. The key is the marketplace name; the value
        must contain a `source` attribute set matching Claude Code's format.
      '';
      example = lib.literalExpression ''
        {
          "context-mode" = {
            source = {
              source = "github";
              repo = "mksglu/context-mode";
            };
          };
        }
      '';
    };

    plugins = lib.mkOption {
      type = lib.types.attrsOf lib.types.bool;
      default = { };
      description = ''
        Plugin enable/disable flags merged into `enabledPlugins` in
        ~/.claude/settings.json. Use the plugin ID as the key.
      '';
      example = lib.literalExpression ''
        {
          "superpowers@claude-plugins-official" = true;
          "typescript-lsp@claude-plugins-official" = true;
          "context-mode@context-mode" = true;
        }
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = ''
        Top-level key/value pairs merged into ~/.claude/settings.json.
        Do not include mcpServers or enabledPlugins here — use the
        dedicated options instead.
      '';
      example = lib.literalExpression ''
        {
          alwaysThinkingEnabled = true;
          voiceEnabled = false;
        }
      '';
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = ''
        MCP server entries merged into mcpServers in ~/.claude/settings.json.
        Each value should be an attribute set matching the Claude Code MCP
        server format (command/args for stdio, type/url for HTTP).
      '';
      example = lib.literalExpression ''
        {
          atlassian = {
            type = "http";
            url = "https://mcp.atlassian.com/v1/mcp";
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.claudeCodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # settings.json — plugins + misc settings (enabledPlugins, alwaysThinkingEnabled, etc.)
      _settings="$HOME/.claude/settings.json"
      _installed="$HOME/.claude/plugins/installed_plugins.json"

      if ! test -f "$_settings"; then
        echo '{}' > "$_settings"
      fi

      ${pkgs.jq}/bin/jq \
        --argjson plugins '${builtins.toJSON cfg.plugins}' \
        --argjson settings '${builtins.toJSON cfg.settings}' \
        --argjson marketplaces '${builtins.toJSON cfg.marketplaces}' \
        '. * $settings
        | .enabledPlugins = ((.enabledPlugins // {}) * $plugins)
        | .extraKnownMarketplaces = ((.extraKnownMarketplaces // {}) * $marketplaces)' \
        "$_settings" > "$_settings.tmp" \
      && mv "$_settings.tmp" "$_settings"

      # .claude.json — user-scoped MCP servers (top-level mcpServers key)
      _claude="$HOME/.claude.json"

      if ! test -f "$_claude"; then
        echo '{}' > "$_claude"
      fi

      ${pkgs.jq}/bin/jq \
        --argjson mcpServers '${builtins.toJSON cfg.mcpServers}' \
        '.mcpServers = ((.mcpServers // {}) * $mcpServers)' \
        "$_claude" > "$_claude.tmp" \
      && mv "$_claude.tmp" "$_claude"

      # Register any declared marketplaces the CLI doesn't already know
      # about. Writing extraKnownMarketplaces into settings.json above is
      # NOT enough by itself — `claude plugin install` only resolves
      # plugins from marketplaces actually registered via `plugin
      # marketplace add` (tracked in known_marketplaces.json). Skipping
      # this step is why a brand-new marketplace's plugins silently fail
      # to install with "not found in marketplace" even though the
      # marketplace is declared.
      _known_marketplaces="$HOME/.claude/plugins/known_marketplaces.json"

      ${lib.concatStrings (lib.mapAttrsToList (name: m: ''
        if ! test -f "$_known_marketplaces" || ! ${pkgs.jq}/bin/jq -e --arg n '${name}' 'has($n)' "$_known_marketplaces" > /dev/null 2>&1; then
          if _mkt_out=$(${pkgs.claude-code}/bin/claude plugin marketplace add '${m.source.repo}' 2>&1); then
            echo "claude-code: [ok] add marketplace ${name}: $_mkt_out"
          else
            echo "claude-code: [FAILED] add marketplace ${name}:"
            echo "$_mkt_out" | sed 's/^/  /'
          fi
        fi
      '') marketplacesToAdd)}

      # Refresh marketplace metadata so the update step below can see new
      # plugin versions (best-effort — a rebuild shouldn't fail offline).
      # Logged either way so a network failure doesn't vanish silently.
      ${lib.optionalString (pluginsToInstall != [ ]) ''
        if _mp_out=$(${pkgs.claude-code}/bin/claude plugin marketplace update 2>&1); then
          echo "claude-code: [ok] refreshed marketplace metadata"
        else
          echo "claude-code: [FAILED] refreshing marketplace metadata (offline?):"
          echo "$_mp_out" | sed 's/^/  /'
        fi
      ''}

      # Install any enabled plugins that are not yet present, and update ones
      # that are already installed. The CLI has no version pinning, so "kept
      # current by Nix" means "updated to latest on every switch" — best-effort
      # (a rebuild shouldn't fail offline), but every attempt is logged as
      # [ok]/[FAILED] with the CLI's own output so a silent failure is visible
      # in the `nurse`/home-manager-switch output instead of just vanishing.
      ${lib.concatMapStrings (plugin: ''
        if ${pkgs.jq}/bin/jq -e --arg p '${plugin}' '.plugins | has($p)' "$_installed" > /dev/null 2>&1; then
          if _plugin_out=$(${pkgs.claude-code}/bin/claude plugin update '${plugin}' 2>&1); then
            echo "claude-code: [ok] update ${plugin}: $_plugin_out"
          else
            echo "claude-code: [FAILED] update ${plugin}:"
            echo "$_plugin_out" | sed 's/^/  /'
          fi
        else
          if _plugin_out=$(${pkgs.claude-code}/bin/claude plugin install '${plugin}' 2>&1); then
            echo "claude-code: [ok] install ${plugin}: $_plugin_out"
          else
            echo "claude-code: [FAILED] install ${plugin}:"
            echo "$_plugin_out" | sed 's/^/  /'
          fi
        fi
      '') pluginsToInstall}
    '';
  };
}
