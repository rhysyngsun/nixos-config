{ pkgs, ... }:
{
  imports = [
    ./desktop
    ./dev
    ./media
    ./open-learning
    ./themes
  ];

  news.display = "silent";
}
