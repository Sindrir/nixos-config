{ pkgs, ... }:
{
  services.desktopManager.cosmic.enable = true;

  environment.sessionVariables = {
    COSMIC_DATA_CONTROL_ENABLED = "1";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-cosmic ];
    config.cosmic.default = [ "cosmic" "gtk" ];
  };
}
