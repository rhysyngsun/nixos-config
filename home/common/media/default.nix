{ pkgs, ... }:
{
  home.packages = with pkgs; [
    spotify
    twitch-dl
  ];
}
