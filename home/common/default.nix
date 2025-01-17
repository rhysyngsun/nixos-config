{ pkgs, inputs, ... }:
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

  home.packages = with inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}; [
    nix-alien
  ];
}
