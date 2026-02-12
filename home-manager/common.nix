{ config, pkgs, ... }:

{
  xdg = {
    enable = true;
    mime.enable = true;
    mimeApps.enable = true;
  };

  programs.link-whisperer.enable = true;
  #targets.genericLinux.enable = true;
  #nixpkgs.allowUnfreePredicate = _: true;

  home = {
    username = "sindreo";
    homeDirectory = "/home/sindreo";
    stateVersion = "25.05";
    packages = with pkgs; [
      # <HOME>

      # CLI
      youtube-tui
      yt-dlp
      mermaid-cli
      helm
      imagemagick
      python3
      google-cloud-sdk-gce
      eza
      bat
      neofetch
      atuin
      kubectl
      gitui
      lazygit
      networkmanagerapplet
      networkmanager-openconnect
      usbutils
      fnm
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
      mountpoint-s3
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

      # Shell
      fish
      oh-my-fish
      starship

      ## Shell extras
      zoxide
      fzf
      yazi

      ## LSP
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
        source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/fish;
        recursive = true;
      };
      ".config/helix" = {
        source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/helix;
        recursive = true;
      };
      ".config/starship.toml" = {
        source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/starship/starship.toml;
      };
      ".config/nvim" = {
        source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/nvim;
        recursive = true;
      };
      ".config/hypr/hyprland.conf" = {
        source = ./dotfiles/config/hypr/hyprland.conf;
      };
      ".config/hypr/hyprpaper.conf" = {
        source = ./dotfiles/config/hypr/hyprpaper.conf;
      };
      # AI Agents symlinks (all point to the same shared config folder)
      ".config/opencode" = {
        source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/ai-agents;
        recursive = true;
      };
      ".config/claude-code" = {
        source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/ai-agents;
        recursive = true;
      };
      ".config/gemini-cli" = {
        source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/ai-agents;
        recursive = true;
      };
      ".config/codex" = {
        source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/ai-agents;
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
