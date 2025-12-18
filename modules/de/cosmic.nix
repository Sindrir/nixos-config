{ pkgs, config, lib, ... }:
let
  # Wrap minimon with NVIDIA library paths so it can access GPU monitoring
  minimon-wrapped = pkgs.symlinkJoin {
    name = "cosmic-ext-applet-minimon-wrapped";
    paths = [ pkgs.cosmic-ext-applet-minimon ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/cosmic-applet-minimon \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
          config.hardware.nvidia.package
          pkgs.addDriverRunpath.driverLink
        ]}"
    '';
  };
in
{
  services.desktopManager.cosmic.enable = true;

  environment = {
    sessionVariables = {
      COSMIC_DATA_CONTROL_ENABLED = "1";
    };
    systemPackages = with pkgs; [
      minimon-wrapped
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-cosmic ];
    config.cosmic.default = [ "cosmic" "gtk" ];
  };
}
