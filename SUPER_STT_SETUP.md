# Super STT Integration Guide

This guide walks you through building and integrating super-stt into your NixOS configuration.

## Overview

Super STT is a speech-to-text application with three components:
- **Daemon** (`super-stt`): Background ML service
- **App** (`super-stt-app`): Configuration GUI
- **Applet** (`super-stt-cosmic-applet`): COSMIC Desktop panel widget

This integration has been set up following NixOS best practices:
- Package defined in `/home/sindreo/nixos-config/packages/super-stt/`
- NixOS module in `/home/sindreo/nixos-config/modules/super-stt.nix`
- Integration example in `/home/sindreo/nixos-config/modules/super-stt-integration.nix`

## Initial Build (First Time Setup)

The first build will fail because we need to get the correct hashes. This is expected and normal.

### Step 1: Initial Build Attempt

```bash
cd /home/sindreo/nixos-config
nix build .#super-stt
```

This will fail with an error like:
```
error: hash mismatch in fixed-output derivation
  specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  got:        sha256-XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX=
```

### Step 2: Update Source Hash

1. Copy the "got:" hash from the error message
2. Edit `/home/sindreo/nixos-config/packages/super-stt/default.nix`
3. Replace the empty `hash = "";` with the hash from the error:
   ```nix
   src = fetchFromGitHub {
     owner = "jorge-menjivar";
     repo = "super-stt";
     rev = "main";
     hash = "sha256-XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxX="; # The hash from error
   };
   ```

### Step 3: Second Build Attempt

```bash
nix build .#super-stt
```

This will fail again with a different error for `cargoHash`:
```
error: hash mismatch in fixed-output derivation
  specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  got:        sha256-YyYyYyYyYyYyYyYyYyYyYyYyYyYyYyYyYyYyYyYyYyY=
```

### Step 4: Update Cargo Hash

1. Copy the "got:" hash from this error
2. Edit `/home/sindreo/nixos-config/packages/super-stt/default.nix` again
3. Replace the empty `cargoHash = "";` with the hash from the error:
   ```nix
   cargoHash = "sha256-YyYyYyYyYyYyYyYyYyYyYyYyYyYyYyYyYyYyYyYyYyY=";
   ```

### Step 5: Final Build

```bash
nix build .#super-stt
```

This should now build successfully! You'll see a `result` symlink pointing to the built package.

### Step 6: Test the Build

```bash
# Test the daemon (will download models on first run)
./result/bin/super-stt --help

# Test the app
./result/bin/super-stt-app
```

## Integration into Your NixOS Configuration

Now that the package builds, you can integrate it into your system.

### Option A: Quick Integration (Recommended)

Add super-stt to your work laptop configuration:

1. Edit `/home/sindreo/nixos-config/hosts/work-laptop/configuration.nix`
2. Add to imports:
   ```nix
   imports = [
     ./hardware-configuration.nix
     ../common.nix
     ../../modules/de/cosmic.nix
     ../../modules/power/system76-power.nix
     ../../modules/super-stt-integration.nix  # Add this line
   ];
   ```

3. Rebuild your system:
   ```bash
   sudo nixos-rebuild switch --flake /home/sindreo/nixos-config#work-laptop
   ```

### Option B: Custom Configuration

If you want more control, import just the module and configure it yourself:

1. Edit `/home/sindreo/nixos-config/hosts/work-laptop/configuration.nix`
2. Add to imports:
   ```nix
   imports = [
     # ... existing imports
     ../../modules/super-stt.nix  # Just the module, not the integration
   ];
   ```

3. Add configuration block:
   ```nix
   services.super-stt = {
     enable = true;
     enableCudaSupport = true;  # You have NVIDIA GPU on work-laptop
     model = "small";            # Or "base", "medium", "large"
     autoStart = false;          # Start manually when needed
     user = "sindreo";
   };
   ```

4. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake /home/sindreo/nixos-config#work-laptop
   ```

### Option C: User Packages Only

If you just want the binaries available without the service:

1. Edit `/home/sindreo/nixos-config/home-manager/common.nix`
2. Add to packages list:
   ```nix
   home.packages = with pkgs; [
     # ... existing packages
     super-stt
   ];
   ```

3. Rebuild:
   ```bash
   home-manager switch --flake /home/sindreo/nixos-config#sindreo
   # OR
   sudo nixos-rebuild switch --flake /home/sindreo/nixos-config#work-laptop
   ```

## Post-Installation Setup

### 1. Start the Service

If you enabled `autoStart = true`, it will start at login. Otherwise:

```bash
# Start daemon
systemctl --user start super-stt

# Check status
systemctl --user status super-stt

# View logs
journalctl --user -u super-stt -f
```

### 2. Configure Super STT

Launch the configuration app:

```bash
super-stt-app
```

Configure:
- **Microphone**: Select your audio input device
- **Language**: Choose your language (default: English)
- **Hotkey**: Set keyboard shortcut (default: Super+Space)
- **Model**: Confirm the model (should match your config)

### 3. Download Models

The first time the daemon runs, it will download the AI models:

```bash
# Watch the logs to see download progress
journalctl --user -u super-stt -f
```

Models are stored in `~/.local/share/super-stt/models/`

Download size depends on model:
- base: ~75 MB
- small: ~150 MB
- medium: ~465 MB
- large: ~1.5 GB

### 4. Test Transcription

1. Ensure the daemon is running: `systemctl --user status super-stt`
2. Open a text editor or any text field
3. Press your hotkey (default: Super+Space)
4. Speak into your microphone
5. Watch as text appears!
6. Press the hotkey again to stop

## COSMIC Desktop Integration (work-laptop)

Since your work-laptop uses COSMIC Desktop:

### Add Panel Applet

1. Right-click on the COSMIC panel
2. Select "Panel Settings" or "Add Applet"
3. Look for "Super STT" in the applet list
4. Click to add to your panel

The applet shows:
- Visual feedback during transcription
- Quick start/stop controls
- Status indicator

## Troubleshooting

### Build Fails with Missing Dependencies

If you get errors about missing Rust dependencies, try:

```bash
# Clear build cache and retry
nix build .#super-stt --rebuild
```

### Models Won't Download

Check internet connection and try manually:

```bash
# Stop the service
systemctl --user stop super-stt

# Run daemon manually to see errors
super-stt
```

### Audio Device Not Found

List available audio devices:

```bash
pactl list sources short
```

Select the correct device in `super-stt-app`.

### GPU Acceleration Not Working

Verify CUDA is available:

```bash
nvidia-smi
```

Check daemon logs for GPU initialization:

```bash
journalctl --user -u super-stt | grep -i cuda
```

### Service Fails to Start

Check logs for specific error:

```bash
journalctl --user -u super-stt -n 100 --no-pager
```

Common issues:
- Model download failed (needs internet)
- Audio device busy (close other apps using mic)
- Permission denied (ensure user in `audio` group)

Verify group membership:

```bash
groups
# Should include "audio"
```

## Advanced Configuration

### GPU Optimization for work-laptop

Your work-laptop has NVIDIA GPU with dynamic power management. For best performance:

```nix
services.super-stt = {
  enable = true;
  enableCudaSupport = true;  # Use GPU when available
  model = "medium";          # Better accuracy with GPU power
  autoStart = false;         # Start when needed to save power
};
```

When running on battery, the GPU might be powered down. The daemon will fall back to CPU.

### Custom Hotkey

If Super+Space conflicts with COSMIC shortcuts:

1. Open `super-stt-app`
2. Go to Settings
3. Choose a different hotkey
4. Save configuration

### Multiple Models

You can install multiple model sizes by running the daemon with different models:

```bash
# Download all models (run daemon with each)
super-stt --model base
super-stt --model small
super-stt --model medium
```

Switch between them in `super-stt-app`.

## Updating Super STT

To update to a newer version:

1. Edit `/home/sindreo/nixos-config/packages/super-stt/default.nix`
2. Change `rev = "main"` to a specific commit hash or tag
3. Clear the hashes:
   ```nix
   hash = "";
   cargoHash = "";
   ```
4. Repeat the initial build process (Steps 1-5 above)
5. Rebuild your configuration

## Performance Tips

### CPU vs GPU

- **CPU (base/small model)**: Lower power, good for battery
- **GPU (medium/large model)**: Better accuracy, needs more power

### Model Selection

- **base**: Fast, uses ~500MB RAM, good accuracy for clear speech
- **small**: Balanced, uses ~1GB RAM, better with accents
- **medium**: Slower, uses ~2.5GB RAM, best for noisy environments
- **large**: Very slow, uses ~5GB RAM, professional accuracy

### Battery Life (work-laptop)

To maximize battery:

```nix
services.super-stt = {
  enable = true;
  enableCudaSupport = false;  # Force CPU mode on battery
  model = "base";             # Fastest model
  autoStart = false;          # Manual start only when needed
};
```

Or use system76-power profiles to automatically disable GPU.

## Uninstalling

To remove super-stt:

```bash
# Stop and disable service
systemctl --user stop super-stt
systemctl --user disable super-stt
```

Remove from configuration:
1. Remove import from host configuration
2. Rebuild: `sudo nixos-rebuild switch --flake /home/sindreo/nixos-config#work-laptop`

Remove models (optional):
```bash
rm -rf ~/.local/share/super-stt/
```

## Getting Help

- Check logs: `journalctl --user -u super-stt -f`
- Upstream issues: https://github.com/jorge-menjivar/super-stt/issues
- Package README: `/home/sindreo/nixos-config/packages/super-stt/README.md`

## Summary of Files Created

```
/home/sindreo/nixos-config/
├── packages/
│   └── super-stt/
│       ├── default.nix           # Package derivation
│       └── README.md             # Package documentation
├── modules/
│   ├── super-stt.nix            # NixOS service module
│   └── super-stt-integration.nix # Example integration
├── flake.nix                     # Updated with super-stt package
└── SUPER_STT_SETUP.md           # This file
```

Now you're ready to build and use super-stt on your NixOS system!
