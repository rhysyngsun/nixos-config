{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland.overrideAttrs(_oa: {
      src = pkgs.fetchFromGitHub {
        owner = "lbonn";
        repo = "rofi";
        rev = "0133697fd2c3c5ca77c7a32f0b30ae750949a027";
        fetchSubmodules = true;
        sha256 = "sha256-eRSLnRK3q7qyZzsExFzPhnq2mfcC2sgRNZxeKw/yYlE=";
      };
    });
    font = "FiraCode Nerd Font 12";
    extraConfig = {
      drun-display-format = "{name}";
    };
  };
  home.packages = with pkgs; [
    rofi-power-menu
  ];
}
