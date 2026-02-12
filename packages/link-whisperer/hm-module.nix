{ config, lib, pkgs, ... }:

let
  cfg = config.programs.link-whisperer;
  link-whisperer = pkgs.callPackage ./default.nix { };
in
{
  options.programs.link-whisperer = {
    enable = lib.mkEnableOption "The Link Whisperer URL dispatcher";

    setAsDefaultBrowser = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Register as default handler for http/https URLs.";
    };

    fishAliases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "cwm" "jetbrains-join" "jbcwm" ];
      description = "Fish shell aliases for join_code_with_me.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      link-whisperer
      pkgs.wl-clipboard
      pkgs.libnotify
      pkgs.wget
      pkgs.steam-run
    ];

    xdg.mimeApps.defaultApplications = lib.mkIf cfg.setAsDefaultBrowser {
      "x-scheme-handler/http" = [ "link-whisperer.desktop" ];
      "x-scheme-handler/https" = [ "link-whisperer.desktop" ];
    };

    programs.fish.shellAliases = lib.listToAttrs (
      map (alias: { name = alias; value = "join_code_with_me"; }) cfg.fishAliases
    );
  };
}
