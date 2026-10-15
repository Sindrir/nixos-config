{ config, lib, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-config/home-manager/dotfiles";
  # Claude Code PreToolUse hook: blocks shell/code-execution tools whose input mentions
  # local secret files or loads .env implicitly (dotenv, loadEnvFile).
  # Complements permissions.deny below, which only covers the built-in file tools.
  # shortcut: matches names in the input text, so indirection (variables, '.e'+'nv') gets past it.
  blockSecretReads = pkgs.writeShellScript "block-secret-reads" ''
    input=$(${pkgs.jq}/bin/jq -r '.tool_input | .. | strings')
    b='[^[:alnum:]_.\\-]' # `\` excluded so regexes like process\.env pass
    secret='(\.env(\.[[:alnum:]_.-]+)?|application(-[[:alnum:]_.-]+)?-local\.(ya?ml|properties|\*)|[[:alnum:]_.*-]*\.pem)'
    loader='load_dotenv|dotenv_values|find_dotenv|dotenv/config|dotenv\.config|loadEnvFile'
    if printf '%s' "$input" | ${pkgs.gnugrep}/bin/grep -qE "(^|$b)$secret($b|$)|$loader"; then
      echo "Blocked: touches a local secret file (.env, application-local.*, *.pem) or loads .env. Ask the user instead." >&2
      exit 2
    fi
  '';
in
{
  home = {
    packages = [ pkgs.claude-code ];

    file = {
      ".config/claude-code" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/ai-agents";
        recursive = true;
      };
      # Global instructions; Claude Code reads ~/.claude/AGENTS.md when no ~/.claude/CLAUDE.md exists
      ".claude/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/ai-agents/AGENTS.md";
    };

    # Idempotent: writes ~/.claude/hooks/herdr-agent-state.sh and merges its hooks into settings.json.
    activation.herdrClaudeIntegration = lib.hm.dag.entryAfter [ "claudeCodeSettings" ] ''
      run ${pkgs.herdr}/bin/herdr integration install claude
    '';
    # Appended with jq rather than via settings: the settings merge replaces arrays and would drop herdr's PreToolUse hook.
    activation.claudeBlockSecretReads = lib.hm.dag.entryAfter [ "herdrClaudeIntegration" ] ''
      _settings="$HOME/.claude/settings.json"
      ${pkgs.jq}/bin/jq --arg cmd "${blockSecretReads}" '
        .hooks.PreToolUse = [(.hooks.PreToolUse // [])[] | select(any(.hooks[]?; .command | test("block-secret-reads")) | not)]
          + [{matcher: "Bash|mcp__plugin_context-mode_context-mode__ctx_(execute|execute_file|batch_execute)", hooks: [{type: "command", command: $cmd}]}]
      ' "$_settings" > "$_settings.tmp" && mv "$_settings.tmp" "$_settings"
    '';
  };

  # Declaratively manages ~/.claude/settings.json via activation script.
  # Add MCP servers per-machine in the relevant host file (e.g. work.nix).
  programs.claude-code-settings = {
    enable = true;

    settings = {
      alwaysThinkingEnabled = true;
      voiceEnabled = false;
      # npm-downloaded Playwright browsers can't run on NixOS; point ad-hoc
      # scripts at the Nix-built ones (npm `playwright` must then be 1.63.x).
      env = {
        PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
        PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
      };
      # Keep local secrets out of context. Only covers built-in file tools, not Bash.
      permissions.deny = map (p: "Read(**/${p})") [
        ".env"
        ".env.*"
        "application-local.*"
        "application-*-local.*"
        "*.pem"
        "*.key"
      ];
    };

    marketplaces = {
      "context-mode" = {
        source = {
          source = "github";
          repo = "mksglu/context-mode";
        };
      };
      # Third-party (MIT), not from the official marketplace — see
      # https://github.com/DietrichGebert/ponytail
      "ponytail" = {
        source = {
          source = "github";
          repo = "DietrichGebert/ponytail";
        };
      };
    };

    plugins = {
      "superpowers@claude-plugins-official" = true;
      "typescript-lsp@claude-plugins-official" = true;
      "kotlin-lsp@claude-plugins-official" = true;
      "rust-analyzer-lsp@claude-plugins-official" = true;
      "lua-lsp@claude-plugins-official" = true;
      # Its PreToolUse hooks intercept Bash/WebFetch/Read/Grep/Agent/all
      # mcp__ tools and redirect them to its own ctx_* MCP tools — the
      # intended workflow, not a bug. Route large-output work through
      # ctx_batch_execute/ctx_execute/ctx_search accordingly instead of
      # raw Bash/WebFetch to avoid the block message; ordinary small reads,
      # file edits, and git/nix-shell commands are unaffected.
      "context-mode@context-mode" = true;
      "ponytail@ponytail" = true;
      "claude-md-management@claude-plugins-official" = true;
      # Runs `npx @playwright/mcp@latest`, whose downloaded browsers can't run
      # on NixOS; replaced by the playwright MCP server below. false (not
      # removed) so the settings merge disables it on machines that have it.
      "playwright@claude-plugins-official" = false;
    };

    mcpServers = {
      atlassian = {
        type = "http";
        url = "https://mcp.atlassian.com/v1/mcp";
      };
      nixos = {
        command = "nix";
        args = [ "run" "github:utensils/mcp-nixos" "--" ];
      };
      # nixpkgs build, wrapped to use the Nix-built browsers
      playwright.command = "${pkgs.playwright-mcp}/bin/playwright-mcp";
    };
  };
}
