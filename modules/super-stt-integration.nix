# Example integration file for super-stt
# Import this in your host configuration to enable super-stt
{ pkgs, ... }:

{
  # Import the super-stt module
  imports = [
    ./super-stt.nix
  ];

  # Enable super-stt service
  services.super-stt = {
    enable = true;

    # Set to true if you have an NVIDIA GPU and want GPU acceleration
    enableCudaSupport = false;

    # Choose your transcription model (base, small, medium, large)
    # Larger models are more accurate but require more resources
    model = "base";

    # Set to true to automatically start the daemon at login
    autoStart = false;

    # User who will run the service
    user = "sindreo";
  };

  # Optionally, add the package directly to user packages for CLI access
  environment.systemPackages = with pkgs; [
    super-stt
  ];
}
