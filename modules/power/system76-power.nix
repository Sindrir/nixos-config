{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.system76-power;

  # Script to switch power profiles based on AC adapter state
  powerSwitchScript = pkgs.writeShellScript "system76-power-switch" ''
    #!/usr/bin/env bash

    # Determine AC adapter state
    if [ -e /sys/class/power_supply/AC ] || [ -e /sys/class/power_supply/AC0 ] || [ -e /sys/class/power_supply/ACAD ]; then
      # Try common AC adapter paths
      for ac_path in /sys/class/power_supply/AC /sys/class/power_supply/AC0 /sys/class/power_supply/ACAD; do
        if [ -e "$ac_path/online" ]; then
          AC_STATE=$(cat "$ac_path/online")
          break
        fi
      done
    else
      # Fallback: check all power supply devices
      AC_STATE=$(cat /sys/class/power_supply/*/online 2>/dev/null | grep -q 1 && echo 1 || echo 0)
    fi

    # Switch profile based on AC state
    if [ "$AC_STATE" = "1" ]; then
      # AC connected - switch to ${cfg.acProfile} profile
      ${pkgs.system76-power}/bin/system76-power profile ${cfg.acProfile}
      ${pkgs.brightnessctl}/bin/brightnessctl set ${toString cfg.acBrightness}%

      ${if cfg.runtimePowerManagement.enable then ''
        # Allow NVIDIA GPU to wake up on AC power (it will activate on-demand via PRIME)
        if [ -e /sys/bus/pci/devices/${cfg.runtimePowerManagement.nvidiaBusId}/power/control ]; then
          echo "on" > /sys/bus/pci/devices/${cfg.runtimePowerManagement.nvidiaBusId}/power/control
          ${pkgs.util-linux}/bin/logger -t system76-power "AC connected: GPU available for on-demand use"
        fi
      '' else if cfg.gpuSwitching.enable then ''
        # Switch to AC graphics mode (requires reboot)
        ${pkgs.system76-power}/bin/system76-power graphics ${cfg.gpuSwitching.acMode}
        ${pkgs.util-linux}/bin/logger -t system76-power "AC adapter connected, switched to ${cfg.acProfile} profile, ${toString cfg.acBrightness}% brightness, and ${cfg.gpuSwitching.acMode} graphics mode (reboot required)"
      '' else ''
        ${pkgs.util-linux}/bin/logger -t system76-power "AC adapter connected, switched to ${cfg.acProfile} profile and ${toString cfg.acBrightness}% brightness"
      ''}
    else
      # AC disconnected - switch to ${cfg.batteryProfile} profile
      ${pkgs.system76-power}/bin/system76-power profile ${cfg.batteryProfile}
      ${pkgs.brightnessctl}/bin/brightnessctl set ${toString cfg.batteryBrightness}%

      ${if cfg.runtimePowerManagement.enable && cfg.runtimePowerManagement.suspendOnBattery then ''
        # Force NVIDIA GPU to power off immediately on battery
        if [ -e /sys/bus/pci/devices/${cfg.runtimePowerManagement.nvidiaBusId}/power/control ]; then
          # First enable runtime PM
          echo "auto" > /sys/bus/pci/devices/${cfg.runtimePowerManagement.nvidiaBusId}/power/control

          # Check if GPU suspended after a moment
          sleep 2
          STATUS=$(cat /sys/bus/pci/devices/${cfg.runtimePowerManagement.nvidiaBusId}/power/runtime_status)
          if [ "$STATUS" != "suspended" ]; then
            # GPU didn't suspend automatically, unload modules to force it
            ${pkgs.kmod}/bin/rmmod nvidia_drm nvidia_modeset nvidia_uvm nvidia 2>/dev/null && \
              ${pkgs.util-linux}/bin/logger -t system76-power "Battery mode: Unloaded NVIDIA modules to force GPU suspend" || \
              ${pkgs.util-linux}/bin/logger -t system76-power "Battery mode: GPU runtime PM enabled (modules in use, will suspend when idle)"
          else
            ${pkgs.util-linux}/bin/logger -t system76-power "Battery mode: NVIDIA GPU automatically suspended"
          fi
        fi
      '' else if cfg.gpuSwitching.enable then ''
        # Switch to battery graphics mode (requires reboot)
        ${pkgs.system76-power}/bin/system76-power graphics ${cfg.gpuSwitching.batteryMode}
        ${pkgs.util-linux}/bin/logger -t system76-power "AC adapter disconnected, switched to ${cfg.batteryProfile} profile, ${toString cfg.batteryBrightness}% brightness, and ${cfg.gpuSwitching.batteryMode} graphics mode (reboot required)"
      '' else ''
        ${pkgs.util-linux}/bin/logger -t system76-power "AC adapter disconnected, switched to ${cfg.batteryProfile} profile and ${toString cfg.batteryBrightness}% brightness"
      ''}
    fi
  '';

in
{
  options.services.system76-power = {
    enable = mkEnableOption "System76 Power Management with automatic profile switching";

    acProfile = mkOption {
      type = types.enum [ "performance" "balanced" "battery" ];
      default = "performance";
      description = ''
        Power profile to use when AC adapter is connected.
        Options: performance, balanced, battery
      '';
    };

    batteryProfile = mkOption {
      type = types.enum [ "performance" "balanced" "battery" ];
      default = "battery";
      description = ''
        Power profile to use when on battery power.
        Options: performance, balanced, battery
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.system76-power;
      defaultText = literalExpression "pkgs.system76-power";
      description = "The system76-power package to use.";
    };

    acBrightness = mkOption {
      type = types.int;
      default = 100;
      description = ''
        Brightness percentage to use when AC adapter is connected (0-100).
      '';
    };

    batteryBrightness = mkOption {
      type = types.int;
      default = 10;
      description = ''
        Brightness percentage to use when on battery power (0-100).
      '';
    };

    gpuSwitching = {
      enable = mkEnableOption "Automatic GPU graphics switching based on power state";

      acMode = mkOption {
        type = types.enum [ "integrated" "nvidia" "hybrid" "compute" ];
        default = "nvidia";
        description = ''
          Graphics mode to use when AC adapter is connected.
          Options:
          - integrated: Use integrated GPU only (iGPU)
          - nvidia: Use NVIDIA GPU only (dGPU active)
          - hybrid: PRIME render offloading (dGPU available on-demand)
          - compute: Use dGPU as compute-only device

          Note: Graphics mode changes require a reboot to take effect.
        '';
      };

      batteryMode = mkOption {
        type = types.enum [ "integrated" "nvidia" "hybrid" "compute" ];
        default = "integrated";
        description = ''
          Graphics mode to use when on battery power.
          Options:
          - integrated: Use integrated GPU only (iGPU) - RECOMMENDED for battery life
          - nvidia: Use NVIDIA GPU only (dGPU active)
          - hybrid: PRIME render offloading (dGPU available on-demand)
          - compute: Use dGPU as compute-only device

          Note: Graphics mode changes require a reboot to take effect.
        '';
      };
    };

    runtimePowerManagement = {
      enable = mkEnableOption "Runtime power management for NVIDIA GPU (dynamic power on/off without reboot)";

      nvidiaBusId = mkOption {
        type = types.str;
        default = "0000:01:00.0";
        description = ''
          PCI bus ID of the NVIDIA GPU (e.g., "0000:01:00.0").
          Find it with: lspci | grep -i nvidia
        '';
      };

      suspendOnBattery = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Automatically suspend (power off) the NVIDIA GPU when on battery.
          This provides immediate power savings without requiring a reboot.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # Install system76-power, brightnessctl, and kmod (if runtime PM enabled)
    environment.systemPackages = [
      cfg.package
      pkgs.brightnessctl
    ] ++ (lib.optionals cfg.runtimePowerManagement.enable [
      pkgs.kmod
    ]);

    # Disable conflicting power management services and configure udev
    services = {
      power-profiles-daemon.enable = mkForce false;
      tlp.enable = mkForce false;

      # Udev rules to trigger power profile switching on AC adapter events
      udev.extraRules = ''
        # Trigger power profile switch when AC adapter state changes
        # Only trigger on main AC adapter (not USB-C power supplies) to prevent rapid cycling
        SUBSYSTEM=="power_supply", KERNEL=="AC|AC0|ACAD", ATTR{online}=="0", TAG+="systemd", ENV{SYSTEMD_WANTS}="system76-power-switch.service"
        SUBSYSTEM=="power_supply", KERNEL=="AC|AC0|ACAD", ATTR{online}=="1", TAG+="systemd", ENV{SYSTEMD_WANTS}="system76-power-switch.service"
      '';
    };

    # Configure systemd services
    systemd.services = {
      # Enable the system76-power systemd service
      system76-power = {
        description = "System76 Power Management";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-logind.service" ];
        serviceConfig = {
          Type = "dbus";
          BusName = "com.system76.PowerDaemon";
          ExecStart = "${cfg.package}/bin/system76-power daemon";
          Restart = "on-failure";
        };
      };

      # Systemd service to switch power profile on AC state change
      system76-power-switch = {
        description = "System76 Power Profile Switcher";
        after = [ "system76-power.service" ];
        requires = [ "system76-power.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = powerSwitchScript;
        };
      };

      # Set the initial power profile on boot
      system76-power-initial = {
        description = "Set initial System76 power profile on boot";
        wantedBy = [ "multi-user.target" ];
        after = [ "system76-power.service" ];
        requires = [ "system76-power.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = powerSwitchScript;
          RemainAfterExit = true;
        };
      };
    };
  };
}
