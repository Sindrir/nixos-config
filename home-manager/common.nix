{ config, lib, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-config/home-manager/dotfiles";
  # Claude Code PreToolUse hook: blocks shell/code-execution tools whose input mentions
  # local secret files or loads .env implicitly (dotenv, loadEnvFile).
  # Complements permissions.deny below, which only covers the built-in file tools.
  # shortcut: matches names in the input text, so indirection (variables, '.e'+'nv') gets past it.
  blockSecretReads = pkgs.writeShellScript "block-secret-reads" ''
    input=$(${pkgs.jq}/bin/jq -r '.tool_input | .. | strings')
    b='[^[:alnum:]_.-]'
    secret='(\.env(\.[[:alnum:]_.-]+)?|application(-[[:alnum:]_.-]+)?-local\.(ya?ml|properties)|[[:alnum:]_.*-]*\.pem)'
    loader='load_dotenv|dotenv_values|find_dotenv|dotenv/config|dotenv\.config|loadEnvFile'
    if printf '%s' "$input" | ${pkgs.gnugrep}/bin/grep -qE "(^|$b)$secret($b|$)|$loader"; then
      echo "Blocked: touches a local secret file (.env, application-local.*, *.pem) or loads .env. Ask the user instead." >&2
      exit 2
    fi
  '';
in
{
  xdg = {
    enable = true;
    mime.enable = true;
    mimeApps.enable = true;
  };

  #targets.genericLinux.enable = true;
  #nixpkgs.allowUnfreePredicate = _: true;

  home = {
    username = "sindreo";
    homeDirectory = "/home/sindreo";
    stateVersion = "25.05";
    packages = with pkgs; [
      # CLI
      github-copilot-cli
      texliveSmall
      pandoc
      gh
      playwright
      sqlcmd
      github-mcp-server
      openssl
      youtube-tui
      yt-dlp
      mermaid-cli
      kubernetes-helm
      imagemagick
      openjpeg
      python3
      google-cloud-sdk-gce
      eza
      bat
      fastfetch
      kubectl
      kubecolor
      gitui
      lazygit
      networkmanagerapplet
      networkmanager-openconnect
      usbutils
      devbox
      pre-commit
      posting
      xclip
      fx
      ripgrep
      gnumake
      unzip
      gcc
      s3fs
      # mountpoint-s3 # Broken for now
      jq
      lsof
      sshfs
      jwt-cli
      presenterm
      steam-run
      claude-code
      jcode
      herdr
      orca-ide
      distrobox
      distrobox-tui
      openconnect
      texlivePackages.pdfjam
      nodejs_24

      # Shell
      fish
      starship

      ## Shell extras
      zoxide
      yazi
      fd
      dust
      duf
      procs
      sd
      ouch
      xh
      viddy
      glow

      ## LSP
      typescript-language-server
      kotlin-language-server
      yaml-language-server
      nginx-language-server
      lua-language-server
      marksman # Markdowm
      nil # Nix
      nixpkgs-fmt # Nix formatting
      statix # Nix linter
      deadnix # Dead code finder
      rustup

      # GUI applications
      ## Comms
      teams-for-linux
      slack
      vesktop # Discord client with proper wayland support
      ungoogled-chromium
      inkscape
      mongodb-compass
      vlc
      remmina
      gimp
      obs-studio
      reaper

      ## Music
      spotify
      #mixing-station

      ## General
      nordpass # Password manager
      kdePackages.okular

      ## Web
      nyxt
      vivaldi
      vivaldi-ffmpeg-codecs
      # zen # Not yet packaged for nix

      ## MISC
      gtk3
      gtk4
      webkitgtk_4_1
      xdg-desktop-portal-gtk
      quick-webapps
      omnissa-horizon-client
      #scribus

      # Programming
      ## Editors
      vim
      helix
      neovim
      zed-editor
      jetbrains-toolbox
      kiro
      vscode
      # jetbrains.idea-ultimate

      ## JDK
      # jdk

      ## API Client
      yaak

      ## Java heap tool
      visualvm

      ## DB
      mongodb-compass
      postgresql # pg_dump, pg_restore, etc.

      ## Docker
      docker
      docker-compose

      ## notes
      obsidian

      ## Sound settings
      pavucontrol
    ];

    file = {
      ".config/fish" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/fish";
        recursive = true;
      };
      ".config/helix" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/helix";
        recursive = true;
      };
      ".config/starship.toml" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/starship/starship.toml";
      };
      ".config/nvim" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/nvim";
        recursive = true;
      };
      ".config/yazi/yazi.toml" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/yazi/yazi.toml";
      };
      ".config/yazi/plugins/jp2.yazi" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/yazi/plugins/jp2.yazi";
      };
      ".config/yazi/keymap.toml" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/yazi/keymap.toml";
      };
      ".config/yazi/plugins/piper.yazi".source = pkgs.yaziPlugins.piper;
      ".config/yazi/plugins/zoom.yazi".source = pkgs.yaziPlugins.zoom;
      ".config/hypr/hyprland.conf" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/hypr/hyprland.conf";
      };
      ".config/hypr/hyprpaper.conf" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/hypr/hyprpaper.conf";
      };
      ".config/claude-code" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/ai-agents";
        recursive = true;
      };
      # Global instructions; Claude Code reads ~/.claude/AGENTS.md when no ~/.claude/CLAUDE.md exists
      ".claude/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/ai-agents/AGENTS.md";
      #       ".config/fish/completions/kubectl.fish".source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/fish/completions/kubectl.fish;
      #       ".config/fish/conf.d/fnm.fish".source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/fish/conf.d/fnm.fish;
      #       ".config/fish/conf.d/omf.fish".source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/fish/conf.d/omf.fish;
      #       ".config/fish/config.fish".source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/fish/config.fish;
      #       ".config/fish/fish_variables".source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/fish/fish_variables;
      #       ".config/helix/config.toml".source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/helix/config.toml;
      #       ".config/helix/languages.toml".source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/helix/languages.toml;
      #       ".config/wezterm/wezterm.lua".source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/wezterm/wezterm.lua;
    };
    sessionVariables = {
      BROWSER = "firefox";
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
  programs = {
    link-whisperer.enable = true;

    # ── Claude Code settings ──────────────────────────────────────────────────
    # Declaratively manages ~/.claude/settings.json via activation script.
    # Add MCP servers per-machine in the relevant host file (e.g. work.nix).
    claude-code-settings = {
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

    # ── Docker MCP Gateway ────────────────────────────────────────────────────
    # Pinned to v0.40.2 — bump packages/docker-mcp/default.nix to update.
    # Browse available servers: docker mcp catalog show docker-mcp
    docker-mcp = {
      enable = true;

      # Register the gateway as an MCP server in Claude Code (stdio transport).
      # Claude Code will start it on demand; no separate daemon needed.
      claudeEnable = true;

      servers = [
        "context7" # Up-to-date code documentation for LLMs
        "fetch" # Fetch URLs and convert to markdown
        "sequentialthinking" # Step-by-step reasoning tool
      ];
    };

    home-manager.enable = true;
    wezterm = {
      enable = true;
      extraConfig = builtins.readFile ./dotfiles/config/wezterm/wezterm.lua;
      #package = (config.lib.nixGL.wrap inputs.wezterm.packages.${pkgs.system}.default);
      #package = inputs.wezterm.packages.${pkgs.system}.default;
    };
    kitty = {
      enable = true;
      settings = {
        shell = "fish";
      };
    };
    tmux = {
      enable = true;
      clock24 = true;
      mouse = true;
      shell = "${pkgs.fish}/bin/fish";
    };
    bottom.enable = true;
    nushell = {
      enable = true;
      extraConfig = ''
        let carapace_completer = {|spans|
        carapace $spans.0 nushell ...$spans | from json
        }
        $env.config = {
         show_banner: false,
         completions: {
         case_sensitive: false # case-sensitive completions
         quick: true    # set to false to prevent auto-selecting completions
         partial: true    # set to false to prevent partial filling of the prompt
         algorithm: "fuzzy"    # prefix or fuzzy
         external: {
         # set to false to prevent nushell looking into $env.PATH to find more suggestions
             enable: true
         # set to lower can improve completion performance at the cost of omitting some options
             max_results: 100
             completer: $carapace_completer # check 'carapace_completer'
           }
         }
        }
        $env.PATH = ($env.PATH |
        split row (char esep) |
        prepend /home/myuser/.apps |
        append /usr/bin/env
        )
      '';
    };
    carapace = {
      enable = true;
      enableNushellIntegration = true;
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    atuin = {
      enable = true;
      enableFishIntegration = false;
      settings.keys.accept_past_line_start = true;
    };
    git = {
      enable = true;
      lfs.enable = true;
      settings = {
        user.name = "Sindre Østrem";
        user.email = "sindre.ostrem@nb.no";
        core.editor = "hx";
        init.defaultBranch = "main";
      };
    };
    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        side-by-side = true;
      };
    };
    fzf = {
      enable = true;
      # atuin owns Ctrl-R; avoid the nushell Ctrl-R conflict between the two.
      historyWidget.nushell.command = "";
    };
    tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };
    pay-respects.enable = true;

  };

  # NOTE: there used to be a systemd.user.services.oo7-daemon unit here,
  # added 2026-06-22 to back COSMIC's XDG portal secret access. It competed
  # with services.gnome.gnome-keyring (hosts/common.nix, since 2026-03-13,
  # with PAM auto-unlock wiring and real consumers: VS Code, MongoDB
  # Compass's --password-store=gnome-libsecret) for the same D-Bus name
  # (org.freedesktop.secrets) — only one can ever hold it, gnome-keyring
  # always won, so oo7-daemon has been permanently failing
  # (Zbus(NameTaken) -> start-limit-hit) on every login/switch since June,
  # marking the user systemd session "degraded" every time. oo7-portal (the
  # actual XDG portal bridge, in modules/de/cosmic.nix) doesn't need
  # oo7-daemon specifically — it talks to whatever Secret Service is on the
  # bus, which is gnome-keyring. Removed rather than reconciled: switching
  # to oo7 as the sole backend would mean losing already-stored secrets
  # (VS Code sign-in, Compass connections) and hand-rolling PAM auto-unlock
  # (oo7-daemon --login) with no NixOS module precedent to build on.

  # Vicinae configuration
  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
    };
  };

  xdg.desktopEntries = {
    # Custom desktop entry for MongoDB Compass for compability with keyring
    mongodb-compass = {
      name = "MongoDB Compass";
      comment = "The MongoDB GUI";
      genericName = "MongoDB Compass";
      exec = "mongodb-compass %u --password-store=\"gnome-libsecret\" --ignore-additional-command-line-flags";
      icon = "mongodb-compass";
      type = "Application";
      startupNotify = true;
      categories = [ "GNOME" "GTK" "Utility" ];
      mimeType = [ "x-scheme-handler/mongodb" "x-scheme-handler/mongodb+srv" ];
    };

    # Used with distrobox to launch nvidia-sync inside ubuntu container
    # distrobox-create --image ubuntu:25.10 -n ubuntu-25.10
    nvidia-sync = {
      name = "Nvidia Sync ";
      comment = "Nvidia Sync for connecting to Spark";
      genericName = "Spark";
      exec = "distrobox-enter --name ubuntu-25.10 -- nvidia-sync";
      icon = "nvidia-settings";
      type = "Application";
      startupNotify = true;
      categories = [ "System" "Utility" ];
      settings = {
        Keywords = "Spark;spark;nvidia;sync;";
      };
    };
  };

  #nixGL = {
  #  packages = import nixgl {inherit pkgs;};
  #  defaultWrapper = "mesa";
  #  offloadWrapper = "nvidiaPrime";
  #  installScripts = [ "mesa" "nvidiaPrime" ];
  #};
}
