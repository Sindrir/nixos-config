{ config, pkgs, inputs, ... }:

{
  xdg = {
    enable = true;
    mime.enable = true;
  };
  #targets.genericLinux.enable = true;
  #nixpkgs.allowUnfreePredicate = _: true;

  home = {
    username = "sindreo";
    homeDirectory = "/home/sindreo";
    stateVersion = "25.05";
    packages = with pkgs; [
      # <HOME>

      # CLI
      wget
      google-cloud-sdk-gce
      eza
      bat
      neofetch
      atuin
      kubectl
      git
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

      ## Music
      spotify

      ## General
      nordpass # Password manager

      ## MISC
      gtk3
      gtk4
      webkitgtk_4_1

      # Programming
      ## Editors
      vim
      helix
      neovim
      zed-editor
      jetbrains-toolbox
      kiro
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

      ## File sync
      megasync

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
      ".config/wezterm" = {
        source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/config/wezterm;
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
      #package = (config.lib.nixGL.wrap inputs.wezterm.packages.${pkgs.system}.default);
      #package = inputs.wezterm.packages.${pkgs.system}.default;
    };
    bottom.enable = true;
  };
  # Custom desktop entry for MongoDB Compass for compability with keyring
  xdg.desktopEntries.mongodb-compass = {
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
  #nixGL = {
  #  packages = import nixgl {inherit pkgs;};
  #  defaultWrapper = "mesa";
  #  offloadWrapper = "nvidiaPrime";
  #  installScripts = [ "mesa" "nvidiaPrime" ];
  #};
}
