{ pkgs, ... }:
{
  imports = [
    ./accounts
    ./desktop
    ./dev
    ./media
    ./open-learning
    ./themes
  ];

  news.display = "silent";
}
