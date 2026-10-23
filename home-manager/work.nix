{ pkgs, ... }:

{
  # Kept after removing the GitHub MCP server; nothing reads these secrets now.
  sops = {
    age.keyFile = "/home/sindreo/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets/github-app.yaml;
    secrets = {
      github_app_id = { };
      github_app_installation_id = { };
      github_app_private_key = { };
    };
  };

  # glvnd picks NVIDIA EGL first, but cosmic-comp composites on the Intel iGPU and
  # sometimes fails to import wezterm's buffers ("import for wrong devices"), which freezes it.
  programs.wezterm.package = pkgs.symlinkJoin {
    name = "wezterm-mesa-egl";
    paths = [ pkgs.wezterm ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for b in wezterm wezterm-gui; do
        wrapProgram $out/bin/$b --set __EGL_VENDOR_LIBRARY_FILENAMES /run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
      done
    '';
  };

  # Slack development huddle - every Tuesday at 09:45
  systemd.user.services.slack-dev-huddle = {
    Unit.Description = "Join Slack development huddle";
    Service = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.libnotify}/bin/notify-send -a 'Slack' -i dialog-information -t 5000 'Development Huddle' 'Joining Slack huddle...'";
      # Detach Slack into its own transient unit; running it here keeps this oneshot activating forever
      ExecStart = "${pkgs.systemd}/bin/systemd-run --user --collect ${pkgs.slack}/bin/slack 'slack://join-huddle?team=T0SNGK4R1&id=C0AENME6PGT'";
    };
  };
  systemd.user.timers.slack-dev-huddle = {
    Unit.Description = "Timer for Slack development huddle";
    Timer = {
      OnCalendar = "Tue *-*-* 09:45:00";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
