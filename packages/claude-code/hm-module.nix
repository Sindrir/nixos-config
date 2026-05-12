{ config, lib, pkgs, ... }:

let
  cfg = config.programs.claude-code-settings;
  # Only plugins set to true need to be installed
  pluginsToInstall = lib.attrNames (lib.filterAttrs (_: v: v) cfg.plugins);
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

      # Install any enabled plugins that are not yet present
      ${lib.concatMapStrings (plugin: ''
        if ! ${pkgs.jq}/bin/jq -e --arg p '${plugin}' '.plugins | has($p)' "$_installed" > /dev/null 2>&1; then
          echo "claude-code: installing plugin ${plugin}"
          ${pkgs.claude-code}/bin/claude plugin install '${plugin}' || true
        fi
      '') pluginsToInstall}
    '';
  };
}
