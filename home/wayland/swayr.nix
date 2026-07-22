{ pkgs, config, ... }:
let
  swayrd = "${pkgs.swayr}/bin/swayrd";
  settingsFormat = pkgs.formats.toml { };
in
{
  xdg.configFile."swayr/config.toml".source = (
    settingsFormat.generate "swayr.toml" {
      menu = {
        executable = "${config.programs.rofi.package}/bin/rofi";
        args = [
          "-dmenu"
          "-markup"
          "-show-icons"
          "-no-case-sensitive"
          "-no-drun-use-desktop-cache"
          "-l 20"
          "-p {prompt}"
        ];
      };
      format = {
        output_format = "{indent}<b>Output {name}</b>    <span alpha=\"20000\">({id})</span>";
        workspace_format = "{indent}<b>Workspace {name} [{layout}]</b>    <span alpha=\"20000\">({id})</span>";
        container_format = "{indent}<b>Container [{layout}]</b> on workspace {workspace_name} <i>{marks}</i>    <span alpha=\"20000\">({id})</span>";
        window_format = "img:{app_icon}:text:{indent}<i>{app_name}</i> — {urgency_start}<b>“{title}”</b>{urgency_end} on workspace {workspace_name} <i>{marks}</i>    <span alpha=\"20000\">({id})</span>";
        indent = "    ";
        urgency_start = "<span background=\"darkred\" foreground=\"yellow\">";
        urgency_end = "</span>";
      };
    }
  );

  systemd.user.services = {
    swayrd = {
      Unit = {
        Description = "Handle monitor connections";
        After = [ "hyprland-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${swayrd}";
        Environment = [ "SWAYSOCK=/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" ];
      };
    };
  };
}
