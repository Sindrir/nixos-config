{ pkgs, config, lib, ... }:
let
  # Wrap minimon with NVIDIA library paths so it can access GPU monitoring
  minimon-wrapped = pkgs.symlinkJoin {
    name = "cosmic-ext-applet-minimon-wrapped";
    paths = [ pkgs.cosmic-ext-applet-minimon ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/cosmic-ext-applet-minimon \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
          config.hardware.nvidia.package
          pkgs.addDriverRunpath.driverLink
        ]}"
    '';
  };
in
{
  services.desktopManager.cosmic.enable = true;

  services.dbus.packages = with pkgs; [ oo7-server oo7-portal ];

  # PipeWire's user sockets are enabled for every user, so the greeter session can
  # socket-activate its own wireplumber. If that happens during login it holds the
  # Bluetooth HSP/HFP profile and the user's wireplumber fails RegisterProfile.
  systemd.user.services.wireplumber.unitConfig.ConditionUser = "!cosmic-greeter";

  environment = {
    sessionVariables = {
      COSMIC_DATA_CONTROL_ENABLED = "1";
    };
    systemPackages = with pkgs; [
      minimon-wrapped
      oo7-portal
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-cosmic oo7-portal ];
    config.cosmic = {
      default = [ "cosmic" "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "oo7-portal" ];
    };
  };
}
