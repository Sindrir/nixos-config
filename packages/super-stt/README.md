# Super STT - Speech-to-Text for NixOS

This is a Nix package for [super-stt](https://github.com/jorge-menjivar/super-stt), a high-performance speech-to-text service for Linux with real-time transcription capabilities.

## Features

- Real-time audio transcription
- Automatic typing capabilities
- GPU acceleration support (NVIDIA CUDA)
- COSMIC Desktop integration
- Norwegian language support via specialized NbAiLab models
- Three components:
  - **Daemon**: Background ML service for transcription
  - **App**: Desktop configuration application
  - **Applet**: COSMIC Desktop panel applet

## Quick Start

### Option 1: Build and Install Directly

The easiest way to try super-stt is to build it directly from the flake:

```bash
# Build the package
nix build /home/sindreo/nixos-config#super-stt

# Try running it
./result/bin/super-stt-app
```

### Option 2: Add to Your Configuration

To integrate super-stt into your NixOS configuration, you have several options:

#### A. Add to host-specific configuration

Edit your host configuration (e.g., `/home/sindreo/nixos-config/hosts/work-laptop/configuration.nix`):

```nix
{
  imports = [
    # ... existing imports
    ../../modules/super-stt.nix
  ];

  # Enable the super-stt service
  services.super-stt = {
    enable = true;
    autoStart = false;  # Set to true to start daemon at login
    model = "base";     # Options: base, small, medium, large
    enableCudaSupport = false;  # Set to true if you have NVIDIA GPU
  };
}
```

#### B. Add package to user packages

If you just want the binaries available without the service, add to your home-manager config:

Edit `/home/sindreo/nixos-config/home-manager/common.nix`:

```nix
{
  home.packages = with pkgs; [
    # ... existing packages
    super-stt
  ];
}
```

### Option 3: Use the Pre-configured Integration Module

The easiest option is to import the pre-configured integration module:

Edit your host configuration:

```nix
{
  imports = [
    # ... existing imports
    ../../modules/super-stt-integration.nix
  ];
}
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake /home/sindreo/nixos-config#work-laptop
```

## Initial Setup

After installation, you'll need to complete the initial setup:

### 1. Download Models

The first time you run super-stt, it will need to download the transcription models:

```bash
# Start the daemon manually (if not auto-started)
super-stt
```

The daemon will download the model specified in your configuration (default: base).

### 2. Configure Audio Input

Launch the configuration app to set up your audio input device:

```bash
super-stt-app
```

Configure:
- Microphone/audio input device
- Language preferences
- Keyboard shortcuts (default: Super+Space)
- Typing behavior

### 3. Start Using

Once configured, you can:

1. **Manual Control**: Start/stop daemon with:
   ```bash
   systemctl --user start super-stt
   systemctl --user stop super-stt
   ```

2. **Keyboard Shortcut**: Press Super+Space (or your configured shortcut) to start transcription

3. **COSMIC Applet**: If using COSMIC Desktop, add the super-stt applet to your panel

## Usage

### Basic Transcription Workflow

1. Press your configured hotkey (default: Super+Space)
2. Speak into your microphone
3. Text is automatically typed where your cursor is
4. Press the hotkey again to stop transcription

### CLI Commands

```bash
# Start daemon
super-stt

# Launch configuration app
super-stt-app

# Launch COSMIC applet (COSMIC Desktop only)
super-stt-cosmic-applet

# Convenience wrapper (same as super-stt)
stt
```

### Systemd Service Management

```bash
# Start the daemon
systemctl --user start super-stt

# Stop the daemon
systemctl --user stop super-stt

# Enable auto-start at login
systemctl --user enable super-stt

# Disable auto-start
systemctl --user disable super-stt

# Check daemon status
systemctl --user status super-stt

# View daemon logs
journalctl --user -u super-stt -f
```

## Configuration Options

### Available Models

#### Standard OpenAI Whisper Models

- `whisper-tiny`: Smallest, fastest, least accurate (good for testing)
- `whisper-base`: Small and fast (good for testing)
- `whisper-small`: Balanced option (recommended for most users)
- `whisper-medium`: Better accuracy, more resources
- `whisper-large`: Best accuracy, highest resource usage
- `whisper-large-v2`: Improved large model
- `whisper-large-v3`: Latest large model
- `whisper-large-v3-turbo`: Optimized version of v3

#### Norwegian National Library Models

This package includes specialized Norwegian whisper models from [NbAiLab](https://huggingface.co/NbAiLab), optimized for Norwegian language (Bokmål and Nynorsk):

- `nb-whisper-tiny`: Smallest Norwegian model, fast but less accurate
- `nb-whisper-base`: Small Norwegian model, good for real-time use
- `nb-whisper-small`: Balanced Norwegian model (recommended for Norwegian users)
- `nb-whisper-medium`: Better accuracy for Norwegian, more resources
- `nb-whisper-large`: Best accuracy for Norwegian, highest resource usage
- `nb-whisper-large-distil-turbo-beta`: Experimental high-speed large Norwegian model

These Norwegian models are specifically trained on Norwegian speech data and will provide significantly better accuracy for Norwegian language transcription compared to the standard multilingual Whisper models.

To use a Norwegian model, specify it in your configuration:

```nix
services.super-stt = {
  enable = true;
  model = "nb-whisper-small";  # or any other nb-whisper-* model
};
```

### GPU Acceleration

If you have an NVIDIA GPU, enable CUDA support:

```nix
services.super-stt = {
  enable = true;
  enableCudaSupport = true;  # Enables GPU acceleration
};
```

This requires:
- NVIDIA GPU with CUDA support
- Sufficient VRAM (varies by model size)
- NVIDIA drivers already configured in NixOS

## Troubleshooting

### Package Build Issues

If the initial build fails with a hash mismatch error:

1. The error message will show the expected hash
2. Edit `/home/sindreo/nixos-config/packages/super-stt/default.nix`
3. Update the `hash` field with the value from the error
4. Rebuild

### Audio Not Working

Ensure PipeWire/PulseAudio is running:

```bash
systemctl --user status pipewire
systemctl --user status pipewire-pulse
```

Check audio input devices:

```bash
pactl list sources short
```

### Service Won't Start

Check logs:

```bash
journalctl --user -u super-stt -n 50
```

Common issues:
- Model download failed (check internet connection)
- Audio device not available
- Permissions issues (ensure user is in `audio` group)

### GPU Acceleration Not Working

Verify NVIDIA drivers:

```bash
nvidia-smi
```

Check CUDA availability:

```bash
nix-shell -p cudatoolkit --run "nvcc --version"
```

## Updating

To update to the latest version:

1. Edit `/home/sindreo/nixos-config/packages/super-stt/default.nix`
2. Update the `rev` field to the latest commit or tag
3. Update the `hash` field (or set to empty string and let build fail with new hash)
4. Rebuild your configuration

## Uninstalling

To remove super-stt:

1. Remove the import from your host configuration
2. Or set `services.super-stt.enable = false;`
3. Rebuild your configuration:
   ```bash
   sudo nixos-rebuild switch --flake /home/sindreo/nixos-config#your-hostname
   ```

## Integration with COSMIC Desktop

If you're using COSMIC Desktop (as configured on work-laptop):

1. The applet will be available after installation
2. Right-click the COSMIC panel
3. Select "Add Panel Applet"
4. Search for "Super STT"
5. Add to panel

The applet provides visual feedback during transcription.

## Advanced Configuration

### Custom Service Configuration

You can override service settings by creating a custom configuration:

```nix
systemd.user.services.super-stt = {
  # Override or extend service settings
  serviceConfig = {
    Environment = [
      "SUPER_STT_CUSTOM_VAR=value"
    ];
  };
};
```

### Per-Host Configuration

Different settings for different machines:

```nix
# work-laptop: Enable GPU, auto-start
services.super-stt = {
  enable = true;
  enableCudaSupport = true;
  autoStart = true;
};

# home-desktop: CPU only, manual start
services.super-stt = {
  enable = true;
  enableCudaSupport = false;
  autoStart = false;
};
```

## Known Limitations

1. **NixOS-specific**: The hash for the source will need to be updated after first build
2. **Model downloads**: First run requires internet connection to download models
3. **COSMIC Desktop**: Applet works best with COSMIC Desktop Environment
4. **GPU support**: Currently CUDA only, no ROCm support yet

## Resources

- [Super STT GitHub](https://github.com/jorge-menjivar/super-stt)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)

## Contributing

To improve this package:

1. Edit `/home/sindreo/nixos-config/packages/super-stt/default.nix`
2. Test your changes: `nix build /home/sindreo/nixos-config#super-stt`
3. Update documentation as needed
4. Commit changes to your configuration repository
