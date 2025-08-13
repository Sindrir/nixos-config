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
      eza
      bat
      neofetch
      atuin
      kubectl
      git
      gitui
      lazygit
      networkmanagerapplet
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

      rustup
      

      # GUI applications
      ## Comms
      teams-for-linux
      slack
      vesktop # Discord client with proper wayland support
      ungoogled-chromium
      inkscape
      mongodb-compass

      ## Gaming
      #steam

      ## Music
      spotify

      ## General
      nordpass # Password manager

      # Programming
      ## Editors
      vim
      helix
      neovim
      zed-editor
      jetbrains-toolbox

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
        source = config.lib.file.mkOutOfStoreSymlink "/home/sindreo/nixos-config/home-manager/dotfiles/config/fish";
        recursive = true;
      };
      ".config/helix" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/sindreo/nixos-config/home-manager/dotfiles/config/helix";
        recursive = true;
      };
      ".config/wezterm" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/sindreo/nixos-config/home-manager/dotfiles/config/wezterm";
        recursive = true;
      };
      ".config/starship.toml" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/sindreo/nixos-config/home-manager/dotfiles/config/starship/starship.toml";
      };
      ".config/nvim" = {
        source = config.lib.file.mkOutOfStoreSymlink "/home/sindreo/nixos-config/home-manager/dotfiles/config/nvim";
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
  xdg.desktopEntries.mongodb-compass = {
    name = "MongoDB Compass";
    comment = "The MongoDB GUI";
    genericName = "MongoDB Compass";
    exec = "mongodb-compass %u --password-store=\"gnome-libsecret\" --ignore-additional-command-line-flags";
    icon = "mongodb-compass";
    type = "Application";
    startupNotify = true;
    categories = ["GNOME" "GTK" "Utility"];
    mimeType = ["x-scheme-handler/mongodb" "x-scheme-handler/mongodb+srv"];
  };
  #nixGL = {
  #  packages = import nixgl {inherit pkgs;};
  #  defaultWrapper = "mesa";
  #  offloadWrapper = "nvidiaPrime";
  #  installScripts = [ "mesa" "nvidiaPrime" ];
  #};
}
