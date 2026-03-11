{ pkgs, ... }:

{
  sops = {
    age.keyFile = "/home/sindreo/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets/github-app.yaml;
    secrets = {
      github_app_id = { };
      github_app_installation_id = { };
      github_app_private_key = { };
    };
  };

  # Slack development huddle - every Tuesday at 09:45
  systemd.user.services.slack-dev-huddle = {
    Unit.Description = "Join Slack development huddle";
    Service = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.libnotify}/bin/notify-send -a 'Slack' -i dialog-information -t 5000 'Development Huddle' 'Joining Slack huddle...'";
      ExecStart = "${pkgs.slack}/bin/slack 'slack://join-huddle?team=T0SNGK4R1&id=C0AENME6PGT'";
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
