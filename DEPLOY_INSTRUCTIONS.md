# Deploy Instructions: Hot-Swappable GPU Power Management

## Current Status
- System in `nvidia` graphics mode (both GPUs active)
- COSMIC showing "Discrete GPU active" warning
- Changes staged but not deployed

## Quick Deploy (3 Commands)

```bash
# 1. Rebuild system with new runtime PM configuration
cd /home/sindreo/nixos-config
sudo nixos-rebuild switch --flake .#work-laptop

# 2. Switch to hybrid mode (one-time, enables runtime PM)
sudo system76-power graphics hybrid

# 3. Reboot (one-time, last reboot for GPU management!)
sudo reboot
```

## After Reboot

### Verify Setup:
```bash
/home/sindreo/nixos-config/scripts/check-gpu-power.sh
```

Should show:
- Graphics Mode: **hybrid** ✓
- Runtime D3: **Enabled** ✓

### Test Hot-Swapping:

**Test 1: Unplug AC**
```bash
# Before unplugging, monitor logs
journalctl -u system76-power-switch.service -f

# Unplug AC adapter
# Within 2-5 seconds you should see:
# "Battery mode: NVIDIA GPU automatically suspended"

# Check GPU state
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
# Should show: suspended
```

**Test 2: Plug AC**
```bash
# Plug AC adapter back in
# Should see: "AC connected: GPU available for on-demand use"

# GPU is ready for use
nvidia-offload glxinfo | grep "OpenGL renderer"
# Should show: NVIDIA GPU
```

## What Changed

### Core Changes:
1. **Runtime PM enabled** in module (no reboot required for power switching)
2. **NVIDIA power management enabled** in hardware config
3. **Graphics switching disabled** (was requiring reboots)

### Files Modified:
- `/home/sindreo/nixos-config/modules/power/system76-power.nix`
- `/home/sindreo/nixos-config/hosts/work-laptop/configuration.nix`

### New Files:
- `/home/sindreo/nixos-config/scripts/check-gpu-power.sh` - Diagnostics
- `/home/sindreo/nixos-config/modules/power/RUNTIME_PM_SETUP.md` - Technical details
- `/home/sindreo/nixos-config/modules/power/SOLUTION_SUMMARY.md` - Complete explanation

## Expected Results

### Battery Life:
- GPU suspends within 2-5 seconds of unplugging AC
- ~5-10W power savings (2-3 hours more battery life)
- COSMIC warning should disappear

### Performance:
- GPU available on-demand when on AC
- No performance loss
- Instant hot-swapping (no reboots)

### Workflow:
- Unplug/plug AC freely - GPU powers on/off automatically
- No user intervention needed
- No reboots required

## Troubleshooting

If GPU doesn't suspend on battery:
```bash
# Check what's using the GPU
lsof /dev/nvidia* 2>/dev/null

# Force module unload
sudo rmmod nvidia_drm nvidia_modeset nvidia_uvm nvidia

# Verify suspension
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
```

## Documentation

Full details in:
- `/home/sindreo/nixos-config/modules/power/SOLUTION_SUMMARY.md`
- `/home/sindreo/nixos-config/modules/power/RUNTIME_PM_SETUP.md`

## Support Commands

```bash
# Live log monitoring
journalctl -u system76-power-switch.service -f

# Full diagnostics
/home/sindreo/nixos-config/scripts/check-gpu-power.sh

# Check graphics mode
system76-power graphics

# Check power profile
system76-power profile

# Manual GPU suspend (on battery)
echo auto | sudo tee /sys/bus/pci/devices/0000:01:00.0/power/control

# Manual GPU wake (on AC)
echo on | sudo tee /sys/bus/pci/devices/0000:01:00.0/power/control
```

---

**Ready to deploy?** Run the 3 commands above!
