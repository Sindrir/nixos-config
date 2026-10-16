{ config, lib, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-config/home-manager/dotfiles";
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
    # The secret-read hook moved to the secret-guard plugin; drop the old Nix-store entry.
    # shortcut: remove once every machine has switched since 2026-10-16.
    activation.claudeDropOldSecretHook = lib.hm.dag.entryAfter [ "herdrClaudeIntegration" ] ''
      _settings="$HOME/.claude/settings.json"
      ${pkgs.jq}/bin/jq '
        if .hooks.PreToolUse then .hooks.PreToolUse |= map(select(any(.hooks[]?; .command | test("block-secret-reads")) | not)) else . end
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
      # Keep local secrets out of context. Covers the built-in file tools and IDE
      # open-file/selection context; the secret-guard plugin covers Bash and code execution.
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
      # Internal NB repo; adding/updating it needs git access to the org.
      "tekst-claude-plugin" = {
        source = {
          source = "github";
          repo = "NationalLibraryOfNorway/tekst-claude-plugin";
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
      # Blocks reading .env/application-local.*/keys via Bash, file tools and code execution
      "secret-guard@tekst-claude-plugin" = true;
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
