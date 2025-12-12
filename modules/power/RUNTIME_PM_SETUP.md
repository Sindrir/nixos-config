# Runtime Power Management Setup for Hot-Swapping GPU Power

## Overview

This configuration enables **dynamic GPU power management without requiring reboots**. The GPU can be powered on/off instantly when switching between AC and battery power.

## Key Changes

### Old Approach (Graphics Mode Switching)
- Used `system76-power graphics integrated|nvidia`
- **Required reboot** after every mode change
- Not practical for mobile use

### New Approach (Runtime Power Management)
- System stays in `hybrid` mode permanently
- NVIDIA driver runtime PM dynamically powers GPU on/off
- **No reboot required** - GPU powers off within ~2 seconds on battery
- GPU available on-demand when on AC power

## Configuration Summary

### In `/home/sindreo/nixos-config/hosts/work-laptop/configuration.nix`:

```nix
services.system76-power = {
  enable = true;
  acProfile = "performance";
  batteryProfile = "battery";

  # NEW: Runtime power management (no reboot required)
  runtimePowerManagement = {
    enable = true;
    nvidiaBusId = "0000:01:00.0";
    suspendOnBattery = true;
  };

  # Graphics switching disabled (was requiring reboots)
  gpuSwitching.enable = false;
};

hardware.nvidia = {
  modesetting.enable = true;

  # CRITICAL: Enable these for runtime PM
  powerManagement.enable = true;
  powerManagement.finegrained = true;

  prime = {
    offload.enable = true;
    offload.enableOffloadCmd = true;
    sync.enable = false;  # Must be false!
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
};
```

## One-Time Setup Required

Since your system is currently in `nvidia` mode, you need to switch to `hybrid` mode once:

```bash
# 1. Switch to hybrid mode (one-time)
sudo system76-power graphics hybrid

# 2. Reboot (one-time)
sudo reboot

# After reboot, runtime PM will handle dynamic power management
```

After this one-time reboot, you'll never need to reboot for GPU power management again.

## How It Works

### On Battery:
1. AC adapter unplugged
2. system76-power-switch.service triggered by udev
3. Script sets GPU PCI power control to `auto`
4. If GPU doesn't suspend automatically, NVIDIA modules are unloaded
5. GPU enters D3 suspended state (powered off)
6. Battery life significantly improved

### On AC:
1. AC adapter plugged in
2. system76-power-switch.service triggered by udev
3. Script sets GPU PCI power control to `on`
4. GPU available for on-demand use via PRIME offloading
5. Use `nvidia-offload <command>` to run apps on dGPU

## Verification Commands

### Check Current Status:
```bash
# Graphics mode (should be "hybrid" after setup)
system76-power graphics

# Power profile
system76-power profile

# AC adapter state
cat /sys/class/power_supply/AC/online

# GPU power state
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
# suspended = GPU is OFF (good for battery)
# active = GPU is ON

# GPU PCI power control
cat /sys/bus/pci/devices/0000:01:00.0/power/control
# auto = runtime PM enabled (GPU can suspend)
# on = runtime PM disabled (GPU stays on)
```

### Monitor Power Switching:
```bash
# Watch system logs
journalctl -u system76-power-switch.service -f

# Run diagnostics script
/tmp/gpu_diagnostics.sh
```

## Testing the Configuration

### After Rebuild and One-Time Reboot:

1. **Verify hybrid mode:**
   ```bash
   system76-power graphics
   # Should show: hybrid
   ```

2. **Test on AC:**
   ```bash
   cat /sys/bus/pci/devices/0000:01:00.0/power/control
   # Should show: on
   cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
   # Can be: active or suspended (both OK on AC)
   ```

3. **Unplug AC adapter and wait 5 seconds:**
   ```bash
   cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
   # Should show: suspended (GPU is OFF!)

   journalctl -u system76-power-switch.service -n 5
   # Should show: "Battery mode: NVIDIA GPU automatically suspended"
   # or: "Battery mode: Unloaded NVIDIA modules to force GPU suspend"
   ```

4. **Plug AC adapter back in:**
   ```bash
   cat /sys/bus/pci/devices/0000:01:00.0/power/control
   # Should show: on

   # GPU will wake up on-demand when you run:
   nvidia-offload glxgears
   ```

## Expected Behavior

### COSMIC Warning:
After this setup, the "Discrete GPU is active" warning should:
- **Disappear on battery** (GPU will be suspended)
- **May still appear on AC** (GPU is available, which is correct)

If the warning persists on battery after the GPU is suspended, it may be a bug in COSMIC's detection logic (it might check for driver presence rather than actual power state).

## Troubleshooting

### GPU Not Suspending on Battery:

```bash
# Check what's using the GPU
lsof /dev/nvidia* 2>/dev/null

# Check loaded NVIDIA modules
lsmod | grep nvidia

# Manually unload modules (to test)
sudo rmmod nvidia_drm nvidia_modeset nvidia_uvm nvidia

# Check GPU state
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
```

### GPU Not Waking on AC:

```bash
# Manually set power control
echo "on" | sudo tee /sys/bus/pci/devices/0000:01:00.0/power/control

# Reload NVIDIA modules
sudo modprobe nvidia nvidia_uvm nvidia_modeset nvidia_drm

# Check driver
nvidia-smi
```

## Rebuild and Deploy

```bash
# Rebuild the system
cd /home/sindreo/nixos-config
sudo nixos-rebuild switch --flake .#work-laptop

# Check if system76-power-switch service updated
systemctl cat system76-power-switch.service | grep -A 20 ExecStart

# One-time switch to hybrid mode
sudo system76-power graphics hybrid

# One-time reboot
sudo reboot
```

After reboot, runtime PM is active and no more reboots needed for GPU power management!
