{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/nixos-config/home-manager/dotfiles";
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
      atuin
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
      codex
      gemini-cli
      opencode
      claude-code
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
      fzf
      yazi

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
      mixing-station

      ## General
      nordpass # Password manager

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
      scribus

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
      ".config/yazi" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/yazi";
      };
      ".config/hypr/hyprland.conf" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/hypr/hyprland.conf";
      };
      ".config/hypr/hyprpaper.conf" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/hypr/hyprpaper.conf";
      };
      # AI Agents symlinks (all point to the same shared config folder)
      ".config/opencode" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/ai-agents";
        recursive = true;
      };
      ".config/claude-code" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/ai-agents";
        recursive = true;
      };
      ".config/gemini-cli" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/ai-agents";
        recursive = true;
      };
      ".config/codex" = {
        source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/ai-agents";
        recursive = true;
      };
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
      };

      marketplaces = {
        "context-mode" = {
          source = {
            source = "github";
            repo = "mksglu/context-mode";
          };
        };
      };

      plugins = {
        "superpowers@claude-plugins-official" = true;
        "typescript-lsp@claude-plugins-official" = true;
        "kotlin-lsp@claude-plugins-official" = true;
        "rust-analyzer-lsp@claude-plugins-official" = true;
        "lua-lsp@claude-plugins-official" = true;
        "context-mode@context-mode" = true;
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

  };

  systemd.user.services.oo7-daemon = {
    Unit = {
      Description = "Secret service (oo7 implementation)";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.oo7-server}/libexec/oo7-daemon";
      Restart = "on-failure";
      TimeoutStartSec = "30s";
      TimeoutStopSec = "30s";
      NoNewPrivileges = true;
      PrivateUsers = "yes";
      ProtectSystem = "full";
      PrivateTmp = true;
      PrivateDevices = true;
      PrivateNetwork = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      MemoryDenyWriteExecute = true;
      ProtectClock = true;
    };
  };

  # Vicinae configuration
  services.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        USE_LAYER_SHELL = 1;
      };
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
