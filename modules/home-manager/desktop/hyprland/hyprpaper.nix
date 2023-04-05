{ pkgs, config, ... }:
{
  home.packages = with pkgs; [
    hyprpaper
  ];

  xdg.dataFile."backgrounds/" = {
    source = ../../../../backgrounds;
    recursive = true;
  };

  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload=${config.xdg.dataHome}/backgrounds/the_valley.png

    wallpaper=,contain:${config.xdg.dataHome}/backgrounds/the_valley.png
  '';
}
