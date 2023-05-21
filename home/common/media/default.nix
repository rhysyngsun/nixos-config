{ pkgs, ... }:
{
  home.packages = with pkgs; [
    (spotify.override {
      # nss = nss_latest;
    })
    #spotifywm
  ];
}
