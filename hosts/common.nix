{ pkgs, lib,  ... }:

{

  imports = [
    ../modules/flatpak.nix
    #  ./jetbrains-nix-ld-fix.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.sindreo = {
    isNormalUser = true;
    description = "Sindre Østrem";
    extraGroups = [ "networkmanager" "wheel" "docker" "audio" ];
    uid = 1000;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

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

  # Increase limits for realtime audio
  security.pam.loginLimits = [
    { domain = "@audio"; type = "-"; item = "rtprio"; value = "95"; }
    { domain = "@audio"; type = "-"; item = "memlock"; value = "unlimited"; }
    { domain = "@audio"; type = "-"; item = "nice"; value = "-19"; }
  ];

  # Configure console keymap
  console.keyMap = "no";

  # Install firefox.
  programs.firefox.enable = true;

  programs.bash.interactiveShellInit = ''eval "$(direnv hook bash)"'';

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  hardware = {
    graphics.enable = true;
    nvidia-container-toolkit.enable = true;
  };

  virtualisation = {
    docker = {
      enable = true;
      daemon = {
        settings = {
          "runtimes" = {
            "nvidia" = {
              "path" = "${pkgs.nvidia-docker}/bin/nvidia-container-runtime";
              "runtimeArgs" = [ ];
            };
          };
        };
      };
    };
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
