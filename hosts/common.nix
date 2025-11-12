{ pkgs, ... }:

{

  imports = [
    ../modules/flatpak.nix
    #  ./jetbrains-nix-ld-fix.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable firewall
  networking.firewall.enable = true;

  # Nix maintenance
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
  };

  # Set your time zone.
  time.timeZone = "Europe/Oslo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nb_NO.UTF-8";
    LC_IDENTIFICATION = "nb_NO.UTF-8";
    LC_MEASUREMENT = "nb_NO.UTF-8";
    LC_MONETARY = "nb_NO.UTF-8";
    LC_NAME = "nb_NO.UTF-8";
    LC_NUMERIC = "nb_NO.UTF-8";
    LC_PAPER = "nb_NO.UTF-8";
    LC_TELEPHONE = "nb_NO.UTF-8";
    LC_TIME = "nb_NO.UTF-8";
  };

  services = {
    flatpak.enable = true;
    displayManager.cosmic-greeter.enable = true;
    xserver.xkb = {
      layout = "no";
      variant = "winkeys";
    };
    printing.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
  };

  # Commented out, trying declarative approach https://www.reddit.com/r/NixOS/comments/1hzgxns/fully_declarative_flatpak_management_on_nixos/
  #systemd.services.flatpak-repo = {
  #  wantedBy = [ "multi-user.target" ];
  #  path = [ pkgs.flatpak ];
  #  script = ''
  #    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  #  '';
  #};

  # Enable realtime scheduling for PipeWire
  security.rtkit.enable = true;

  # Configure console keymap
  console.keyMap = "no";

  # Install firefox.
  programs.firefox.enable = true;

  programs.bash.interactiveShellInit = ''eval "$(direnv hook bash)"'';

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  virtualisation = {
    docker.enable = true;
    #    podman = {
    #      enable = true;
    #      dockerCompat = true;
    #    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    curl
    wget
    # Add more common system packages here
    direnv
  ];
  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };
}
