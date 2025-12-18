# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../common.nix
      ../../modules/de/cosmic.nix
    ];

  boot.extraModprobeConfig = ''
    options snd-hda-intel model=auto
    options snd-intel-dspcfg dsp_driver=1
    options snd-hda-intel power_save=0
  '';

  services.pipewire = {
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 2048;
      };
    };
    extraConfig.pipewire-pulse."92-low-latency" = {
      "pulse.properties" = {
        "pulse.min.req" = "512/48000";
        "pulse.default.req" = "512/48000";
        "pulse.max.req" = "512/48000";
        "pulse.min.quantum" = "512/48000";
        "pulse.max.quantum" = "512/48000";
      };
      "stream.properties" = {
        "node.latency" = "512/48000";
        "resample.quality" = 4;
      };
    };
    wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/99-ssl2-config.conf" ''
        monitor.alsa.rules = [
          {
            matches = [
              { node.name = "~alsa_output.*" }
            ]
            actions = {
              update-props = {
                audio.format = "S24LE"
                audio.rate = 48000
                api.alsa.period-size = 512
                api.alsa.headroom = 1024
                session.suspend-timeout-seconds = 0
              }
            }
          }
          {
            matches = [
              { node.name = "~alsa_input.*" }
            ]
            actions = {
              update-props = {
                audio.format = "S24LE"
                audio.rate = 48000
                api.alsa.period-size = 512
                api.alsa.headroom = 1024
                session.suspend-timeout-seconds = 0
              }
            }
          }
        ]
      '')
      # Temporarily disabled - causing SSL2+ node creation to fail
      # (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-disable-ucm.conf" ''
      #   monitor.alsa.rules = [
      #     {
      #       matches = [
      #         { device.name = "~alsa_card.*" }
      #       ]
      #       actions = {
      #         update-props = {
      #           api.alsa.use-ucm = false
      #         }
      #       }
      #     }
      #   ]
      # '')
    ];
  };

  # Add extra home-manager packages specific to this host
  home-manager.users.sindreo = {
    home.packages = with pkgs; [
      ## File sync
      megasync
    ];
  };

  environment.shellAliases = {
    tree = "eza --tree";
    nurse = "sudo nixos-rebuild switch --flake /etc/nixos#home-desktop";
  };
  hardware = {
    nvidia = {
      modesetting.enable = true;
      open = false;
      nvidiaSettings = true;
    };
  };

  networking.hostName = "home-desktop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  services = {
    xserver = {
      videoDrivers = [ "nvidia" ];
      enable = true;
    };
    printing.enable = true;
  };


  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    mangohud
    protonup-qt
    lutris
    bottles
    heroic
  ];
  programs = {
    steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
    gamemode.enable = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
