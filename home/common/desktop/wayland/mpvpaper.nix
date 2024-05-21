{ pkgs, ... }:
let
  wallpaper = ../../../../backgrounds/wallpaper-compressed.mp4;
in
{
  home.packages = with pkgs; [ mpvpaper ];

  systemd.user.services."mpvpaper" = {
    Unit = {
      After = "graphical-session.target";
      PartOf = "graphical-session.target";
      Requires = "graphical-session.target";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.mpvpaper}/bin/mpvpaper '*' -o 'no-audio loop' ${wallpaper}";
      Restart = "on-failure";
      ExecSearchPath = "${pkgs.mpvpaper}/bin";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
