# Example integration file for super-stt
# Import this in your host configuration to enable super-stt
{ pkgs, ... }:

{
  # Import the super-stt module
  imports = [
    ./super-stt.nix
  ];

  # Enable super-stt service with Norwegian models
  services.super-stt = {
    enable = true;

    # Set to true if you have an NVIDIA GPU and want GPU acceleration
    enableCudaSupport = false;

    # Default Norwegian whisper model to use
    # Available: nb-whisper-tiny, nb-whisper-base, nb-whisper-small,
    #            nb-whisper-medium, nb-whisper-large, nb-whisper-large-distil-turbo-beta
    model = "nb-whisper-small";

    # Set to true to automatically start the daemon at login
    autoStart = false;

    # User who will run the service
    user = "sindreo";

    # Pre-download all Norwegian whisper models so you can switch between them
    norwegianModels = [
      "nb-whisper-tiny"
      "nb-whisper-base"
      "nb-whisper-small"
      "nb-whisper-medium"
      "nb-whisper-large"
      "nb-whisper-large-distil-turbo-beta"
    ];
  };

  # Optionally, add the package directly to user packages for CLI access
  environment.systemPackages = with pkgs; [
    super-stt
  ];
}
