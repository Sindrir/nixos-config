# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  # Use /etc/nixos/hosts.nix for private host entries (not in git)
  hostsFile = /etc/nixos/hosts.nix;
  hostsFileExists = builtins.pathExists hostsFile;
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../common.nix
      ../../modules/de/cosmic.nix
      ../../modules/power/system76-power.nix
      #../../modules/super-stt-integration.nix
    ]
    ++ lib.optionals hostsFileExists [ hostsFile ];

  networking.hostName = "work-laptop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Cosmic Desktop Environment enabled via imported module.

  # Enable system76-power with automatic power profile switching
  services.system76-power = {
    enable = true;
    acProfile = "performance"; # Use performance mode when plugged in
    batteryProfile = "battery"; # Use battery mode when on battery

    # Runtime power management - dynamically power off GPU without reboots
    runtimePowerManagement = {
      enable = true;
      nvidiaBusId = "0000:01:00.0"; # Your NVIDIA GPU PCI bus ID
      suspendOnBattery = true; # Automatically power off GPU when on battery
    };

    # GPU switching configuration (requires reboot - DISABLED in favor of runtime PM)
    gpuSwitching = {
      enable = false; # Disabled - using runtime PM instead for instant switching
      # When disabled, system stays in hybrid mode permanently
      # Runtime PM controls actual GPU power state dynamically
    };
  };

  services = {
    gnome.gnome-keyring.enable = true;
    xserver.videoDrivers = [ "nvidia" ];
  };
  hardware = {
    nvidia = {
      modesetting.enable = true;

      # Enable power management for runtime PM (dynamic GPU power on/off)
      powerManagement.enable = true;
      # Enable fine-grained power management (allows GPU to suspend when idle)
      powerManagement.finegrained = true;

      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        # Use offload mode for PRIME render offloading (hybrid graphics)
        # GPU is available on-demand but can be powered off when not in use
        offload = {
          enable = true;
          enableOffloadCmd = true; # Provides 'nvidia-offload' command
        };
        # Disable sync mode (would force both GPUs to always be active)
        sync.enable = false;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cifs-utils
    lshw
    wrapGAppsHook4
  ];

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
