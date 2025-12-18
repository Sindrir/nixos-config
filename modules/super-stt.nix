{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.super-stt;
in
{
  options.services.super-stt = {
    enable = mkEnableOption "Super STT speech-to-text service";

    package = mkOption {
      type = types.package;
      default = pkgs.super-stt.override {
        cudaSupport = cfg.enableCudaSupport;
      };
      defaultText = literalExpression "pkgs.super-stt";
      description = "The super-stt package to use.";
    };

    user = mkOption {
      type = types.str;
      default = "sindreo";
      description = "User account under which super-stt runs.";
    };

    enableCudaSupport = mkOption {
      type = types.bool;
      default = false;
      description = "Enable CUDA GPU acceleration for transcription (requires NVIDIA GPU).";
    };

    model = mkOption {
      type = types.str;
      default = "base";
      description = "Transcription model to use (e.g., base, small, medium, large).";
    };

    autoStart = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically start the super-stt daemon at login.";
    };

    norwegianModels = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of Norwegian whisper models to pre-download.";
      example = [ "nb-whisper-tiny" "nb-whisper-base" "nb-whisper-small" ];
    };
  };

  config = mkIf cfg.enable {
    # Add the package to system packages
    environment.systemPackages = [ cfg.package ];

    # Add user to necessary groups for audio access
    users.users.${cfg.user}.extraGroups = [ "audio" ];

    # Create user services for super-stt and model downloads
    systemd.user.services = mkMerge [
      # Main super-stt daemon service
      {
        super-stt = {
          description = "Super STT Daemon";
          after = [ "network.target" ];
          wantedBy = mkIf cfg.autoStart [ "default.target" ];

          serviceConfig = {
            Type = "simple";
            ExecStart = "${cfg.package}/bin/super-stt";
            Restart = "on-failure";
            RestartSec = "5";
          };

          # Set environment variables if needed
          environment = mkIf cfg.enableCudaSupport {
            # CUDA-related environment variables
            LD_LIBRARY_PATH = lib.makeLibraryPath [
              pkgs.cudaPackages.cuda_cudart
              pkgs.cudaPackages.cuda_nvrtc
              pkgs.cudaPackages.libcurand
              pkgs.cudaPackages.cudnn
              pkgs.cudaPackages.libcublas
            ];
          };
        };
      }

      # Norwegian model download services
      (listToAttrs (map
        (modelName: {
          name = "super-stt-download-${modelName}";
          value = {
            description = "Download Norwegian whisper model ${modelName}";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${cfg.package}/bin/super-stt --model ${modelName} --download-only || true";
            };
          };
        })
        cfg.norwegianModels))
    ];

    # Enable PulseAudio/PipeWire support (already configured in common.nix)
    # Just ensure audio is available
  };
}
