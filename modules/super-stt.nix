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
      default = pkgs.super-stt;
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
  };

  config = mkIf cfg.enable {
    # Add the package to system packages
    environment.systemPackages = [ cfg.package ];

    # Create a user service for super-stt
    systemd.user.services.super-stt = {
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
        LD_LIBRARY_PATH = "${pkgs.cudaPackages.cudatoolkit}/lib";
      };
    };

    # Add user to necessary groups for audio access
    users.users.${cfg.user}.extraGroups = [ "audio" ];

    # Enable PulseAudio/PipeWire support (already configured in common.nix)
    # Just ensure audio is available
  };
}
