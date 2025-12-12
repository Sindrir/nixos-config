# System76 Power Management Module

This module provides automatic power profile switching for NixOS systems using `system76-power`, particularly useful for laptops running COSMIC desktop environment.

## Features

- Automatic power profile switching based on AC adapter state
- Three available power profiles: `performance`, `balanced`, and `battery`
- Configurable profiles for AC and battery states
- Uses udev rules to detect AC adapter changes in real-time
- Automatically disables conflicting power management services (TLP, power-profiles-daemon)

## Configuration

### Basic Setup

Add the module to your NixOS configuration imports:

```nix
imports = [
  ./modules/power/system76-power.nix
];
```

Enable the service with default settings (performance on AC, battery on battery):

```nix
services.system76-power = {
  enable = true;
  acProfile = "performance";    # Profile when plugged in
  batteryProfile = "battery";   # Profile when on battery
};
```

### Available Options

#### `services.system76-power.enable`
- Type: `boolean`
- Default: `false`
- Enable System76 Power Management with automatic profile switching

#### `services.system76-power.acProfile`
- Type: `enum ["performance" "balanced" "battery"]`
- Default: `"performance"`
- Power profile to use when AC adapter is connected

#### `services.system76-power.batteryProfile`
- Type: `enum ["performance" "balanced" "battery"]`
- Default: `"battery"`
- Power profile to use when on battery power

#### `services.system76-power.package`
- Type: `package`
- Default: `pkgs.system76-power`
- The system76-power package to use

#### `services.system76-power.gpuSwitching.enable`
- Type: `boolean`
- Default: `false`
- Enable automatic GPU graphics switching based on power state (AC/battery)

#### `services.system76-power.gpuSwitching.acMode`
- Type: `enum ["integrated" "nvidia" "hybrid" "compute"]`
- Default: `"nvidia"`
- Graphics mode when AC adapter is connected
- Options:
  - `integrated`: Use integrated GPU only (iGPU)
  - `nvidia`: Use NVIDIA GPU only (dGPU active) - best performance
  - `hybrid`: PRIME render offloading (dGPU available on-demand)
  - `compute`: Use dGPU as compute-only device
- Note: Graphics mode changes require a reboot to take effect

#### `services.system76-power.gpuSwitching.batteryMode`
- Type: `enum ["integrated" "nvidia" "hybrid" "compute"]`
- Default: `"integrated"`
- Graphics mode when on battery power
- Options:
  - `integrated`: Use integrated GPU only (iGPU) - RECOMMENDED for maximum battery life
  - `nvidia`: Use NVIDIA GPU only (dGPU active)
  - `hybrid`: PRIME render offloading (dGPU available on-demand)
  - `compute`: Use dGPU as compute-only device
- Note: Graphics mode changes require a reboot to take effect

### Profile Descriptions

**Performance Mode:**
- Maximum performance settings
- No CPU throttling
- Higher power consumption
- Best for demanding workloads

**Balanced Mode:**
- Moderate settings
- Disk sync intervals enabled
- Kernel laptop mode active
- Good balance between performance and battery life

**Battery Mode:**
- Aggressive power conservation
- Reduced screen brightness
- Maximum CPU throttling
- Keyboard backlight control
- Optimized for maximum battery life

## How It Works

### Architecture

The module implements automatic power profile switching using three components:

1. **System76-power Daemon (`system76-power.service`)**
   - Main daemon that manages power profiles
   - Communicates via D-Bus
   - Provides `com.system76.PowerDaemon` interface

2. **Udev Rules**
   - Monitors `/sys/class/power_supply/*/online` for AC adapter state changes
   - Triggers `system76-power-switch.service` on state changes
   - Detects both plug and unplug events

3. **Power Switch Service (`system76-power-switch.service`)**
   - Oneshot systemd service triggered by udev
   - Checks AC adapter state from sysfs
   - Executes `system76-power profile <mode>` command
   - Logs actions to system journal

### Execution Flow

```
AC Adapter Event → Udev Rule → Systemd Service → Check AC State → Switch Profile
                                                                        ↓
                                                              system76-power profile
```

### Initial State on Boot

The module includes `system76-power-initial.service` that:
- Runs once on system boot
- Checks current AC adapter state
- Sets appropriate power profile
- Ensures correct profile is active from boot

## Compatibility

### Conflicts with Other Power Management Tools

This module automatically disables conflicting services:
- `services.power-profiles-daemon.enable = false`
- `services.tlp.enable = false`

If you have these services configured elsewhere in your system, the module will override them with `mkForce`.

### Desktop Environment Integration

Works seamlessly with:
- COSMIC Desktop Environment
- GNOME (with gnome-keyring)
- KDE Plasma
- Other desktop environments

Note: Some desktop environments may show warnings about missing power-profiles-daemon. This is expected and normal.

## Testing

### Verify Installation

After rebuilding your system, check that the service is running:

```bash
systemctl status system76-power.service
```

### Check Current Profile

```bash
system76-power profile
```

### Manual Profile Switching

Test manual switching:

```bash
# Switch to performance
sudo system76-power profile performance

# Switch to battery
sudo system76-power profile battery

# Switch to balanced
sudo system76-power profile balanced
```

### Test Automatic Switching

1. While plugged in, check the current profile:
   ```bash
   system76-power profile
   # Should show: performance (or your configured acProfile)
   ```

2. Unplug AC adapter and check logs:
   ```bash
   journalctl -u system76-power-switch.service -f
   # Should show: "AC adapter disconnected, switched to battery profile"
   ```

3. Verify profile changed:
   ```bash
   system76-power profile
   # Should show: battery (or your configured batteryProfile)
   ```

4. Plug AC adapter back in and repeat verification

### Troubleshooting

**Service fails to start:**
```bash
# Check service status and logs
systemctl status system76-power.service
journalctl -u system76-power.service -n 50
```

**Automatic switching not working:**
```bash
# Verify udev rules are loaded
udevadm control --reload-rules

# Check AC adapter path
find /sys/class/power_supply -name "online" -exec cat {} \;

# Monitor udev events
udevadm monitor --environment --udev | grep power_supply
```

**Profile not applying:**
```bash
# Check D-Bus service
busctl status com.system76.PowerDaemon

# Manually trigger switch
sudo systemctl start system76-power-switch.service
```

## Integration with NVIDIA Optimus

For systems with NVIDIA Optimus (hybrid graphics), this module provides automatic graphics mode switching:

### Manual Commands

You can also manually control graphics modes:
- `system76-power graphics` - Show current graphics mode
- `system76-power graphics integrated` - Use integrated GPU only
- `system76-power graphics nvidia` - Use NVIDIA GPU
- `system76-power graphics hybrid` - PRIME render offloading
- `system76-power graphics compute` - dGPU as compute-only device

Note: Graphics mode changes require a reboot to take effect.

### Automatic GPU Switching

Enable automatic GPU switching based on power state:

```nix
services.system76-power = {
  enable = true;
  acProfile = "performance";
  batteryProfile = "battery";

  gpuSwitching = {
    enable = true;
    acMode = "nvidia";       # Use discrete GPU when plugged in
    batteryMode = "integrated"; # Use integrated GPU on battery
  };
};
```

**Important NVIDIA Configuration for GPU Switching:**

When using GPU switching, you MUST configure NVIDIA to use offload mode (not sync mode):

```nix
hardware.nvidia.prime = {
  offload = {
    enable = true;
    enableOffloadCmd = true;
  };
  sync.enable = false; # IMPORTANT: Disable sync mode
  intelBusId = "PCI:0:2:0";
  nvidiaBusId = "PCI:1:0:0";
};
```

Sync mode forces both GPUs to always be active, which prevents power savings. Offload mode allows the discrete GPU to be fully powered down when not needed.

## Example Configuration

### Work Laptop with Hybrid Graphics and GPU Switching

```nix
{
  imports = [
    ./modules/power/system76-power.nix
  ];

  services.system76-power = {
    enable = true;
    acProfile = "performance";
    batteryProfile = "battery";

    # Automatically switch GPU modes based on power state
    gpuSwitching = {
      enable = true;
      acMode = "nvidia";       # Use discrete GPU when plugged in for performance
      batteryMode = "integrated"; # Use integrated GPU on battery for longer battery life
    };
  };

  # NVIDIA configuration - MUST use offload mode for GPU switching
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    prime = {
      # Use offload mode to allow system76-power to manage GPU switching
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      sync.enable = false; # Disable sync - it keeps both GPUs active
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
```

### Desktop with Consistent Performance

```nix
{
  imports = [
    ./modules/power/system76-power.nix
  ];

  services.system76-power = {
    enable = true;
    # Desktop doesn't have battery, but service won't fail
    acProfile = "performance";
    batteryProfile = "performance";  # Unused on desktop
  };
}
```

## Additional Resources

- [System76 Power GitHub Repository](https://github.com/pop-os/system76-power)
- [NixOS Power Management Wiki](https://wiki.nixos.org/wiki/Power_Management)
- [System76 Support - Battery Life](https://support.system76.com/articles/battery/)

## Credits

This module was created to provide seamless automatic power profile switching for NixOS systems using the COSMIC desktop environment, based on the system76-power utility from Pop!_OS.
