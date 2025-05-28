{pkgs, ...}: {
  home.packages = with pkgs; [
    spotify
    # twitch-dl

    # audio production
    audacity
    helm
    lmms
  ];
}
