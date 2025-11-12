{ pkgs, ... }:
{
  # Enable Hyprland Wayland compositor
  programs.hyprland.enable = true;

  # Set environment variables for Wayland compatibility
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    XDG_SESSION_TYPE = "wayland";
    SDL_VIDEODRIVER = "wayland";
  };

  # Recommended packages for Hyprland setups
  environment.systemPackages = with pkgs; [
    hyprland
    waybar
    wofi
    xdg-desktop-portal-hyprland
    xdg-desktop-portal
    xdg-utils
    wl-clipboard
    grim
    slurp
    swaylock
    swayidle
    mako
    dunst
    alacritty
    kitty
    foot
    # Add more as needed
  ];

  # Do not enable X11
  # services.xserver.enable = false;
}
