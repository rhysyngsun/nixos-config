{ pkgs, ... }:
{
  home.packages = with pkgs; [
    spotify
    twitch-dl

    # audio production
    # audacity
    # zrythm
    # helm
    # lmms
  ];
}
