{ config, pkgs, ... }:

{

  imports = [
    ../modules/flatpak.nix
    #  ./jetbrains-nix-ld-fix.nix
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Cachix binary cache for vicinae
    extra-substituters = [ "https://vicinae.cachix.org" ];
    extra-trusted-public-keys = [
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
    ];
    cores = 0;
    max-jobs = "auto";
    keep-outputs = true;
  };

  boot = {
    # Bootloader configuration
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = 2;
    };

    # v4l2loopback: virtual webcam device for webcam effects applet
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    kernelModules = [ "v4l2loopback" ];
    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=2 card_label="Virtual Webcam" exclusive_caps=1
    '';

    tmp.cleanOnBoot = true;

    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.sindreo = {
    isNormalUser = true;
    description = "Sindre Østrem";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    uid = 1000;
  };

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
    optimise = {
      automatic = true;
      dates = [ "daily" ];
      persistent = true;
    };
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

  zramSwap.enable = true;

  services = {
    flatpak.enable = true;
    earlyoom.enable = true;
    thermald.enable = true;
    fstrim.enable = true;
    locate = {
      enable = true;
      package = pkgs.plocate;
    };
    journald.extraConfig = ''
      SystemMaxUse=1G
    '';
    displayManager.cosmic-greeter.enable = true;

    # Gnome Keyring — system-wide secret store (libsecret / secret-service protocol).
    # Used by: Docker MCP secrets, MongoDB Compass, VS Code, and any app using libsecret.
    gnome.gnome-keyring.enable = true;
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

  security = {
    # Enable realtime scheduling for PipeWire
    rtkit.enable = true;

    sudo.extraConfig = ''
      Defaults pwfeedback
      Defaults lecture=never
      Defaults timestamp_timeout=30
    '';

    # Auto-unlock gnome-keyring when the user logs in.
    # cosmic-greeter handles the Wayland session; login covers TTY/SSH.
    pam.services = {
      login.enableGnomeKeyring = true;
      cosmic-greeter.enableGnomeKeyring = true;
    };
  };

  # Configure console keymap
  console.keyMap = "no";

  programs = {
    firefox.enable = true;
    bash.interactiveShellInit = ''eval "$(direnv hook bash)"'';
    nix-ld.enable = true;
    nix-index.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # vesktop (Discord client) build-depends on pnpm which was flagged insecure
  # pnpm is a build-time-only tool and does not end up on the system
  nixpkgs.config.permittedInsecurePackages = [ "pnpm-10.29.2" ];

  hardware = {
    graphics.enable = true;
    nvidia-container-toolkit.enable = true;
    cpu.intel.updateMicrocode = true;
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
    git-lfs
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
