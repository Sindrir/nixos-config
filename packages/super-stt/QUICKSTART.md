# Super STT Quick Start

## TL;DR - Get Started in 5 Steps

### 1. Initial Build (get hashes)

```bash
cd /home/sindreo/nixos-config

# First attempt - will fail and give you the source hash
nix build .#super-stt
# Copy the hash from error, update packages/super-stt/default.nix line 25

# Second attempt - will fail and give you the cargo hash
nix build .#super-stt
# Copy the hash from error, update packages/super-stt/default.nix line 29

# Third attempt - should succeed!
nix build .#super-stt
```

### 2. Test It Works

```bash
./result/bin/super-stt-app
```

### 3. Add to Your Configuration

Edit `/home/sindreo/nixos-config/hosts/work-laptop/configuration.nix`:

```nix
imports = [
  # ... existing imports ...
  ../../modules/super-stt-integration.nix  # Add this line
];
```

### 4. Rebuild System

```bash
sudo nixos-rebuild switch --flake /home/sindreo/nixos-config#work-laptop
```

### 5. Start Using

```bash
# Start the daemon
systemctl --user start super-stt

# Open config app
super-stt-app

# Press Super+Space and speak!
```

## Common Commands

```bash
# Service management
systemctl --user start super-stt
systemctl --user stop super-stt
systemctl --user status super-stt
systemctl --user enable super-stt   # Auto-start at login
systemctl --user disable super-stt  # Don't auto-start

# View logs
journalctl --user -u super-stt -f

# Launch apps
super-stt-app                    # Config GUI
super-stt                        # Daemon (manual start)
super-stt-cosmic-applet          # COSMIC panel widget
```

## Configuration Locations

- **Package**: `/home/sindreo/nixos-config/packages/super-stt/default.nix`
- **Module**: `/home/sindreo/nixos-config/modules/super-stt.nix`
- **Integration**: `/home/sindreo/nixos-config/modules/super-stt-integration.nix`
- **Models**: `~/.local/share/super-stt/models/`
- **User Config**: `~/.config/super-stt/`

## Module Options

```nix
services.super-stt = {
  enable = true;                    # Enable the service
  enableCudaSupport = false;        # Use NVIDIA GPU
  model = "base";                   # base/small/medium/large
  autoStart = false;                # Start at login
  user = "sindreo";                 # User to run service
};
```

## Troubleshooting One-Liners

```bash
# Check if daemon is running
systemctl --user is-active super-stt

# Test audio devices
pactl list sources short

# Check GPU
nvidia-smi

# Restart service
systemctl --user restart super-stt

# See last 50 log lines
journalctl --user -u super-stt -n 50

# Check if models downloaded
ls -lh ~/.local/share/super-stt/models/

# Force model re-download (stop service first!)
rm -rf ~/.local/share/super-stt/models/ && systemctl --user start super-stt
```

## Full Documentation

- Setup Guide: `/home/sindreo/nixos-config/SUPER_STT_SETUP.md`
- Package README: `/home/sindreo/nixos-config/packages/super-stt/README.md`
- Upstream: https://github.com/jorge-menjivar/super-stt
