{ pkgs, ... }:
let
  mochaTheme = (pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "themes";
    rev = "47fe578a92ab7862afb32f0eb497772da01bbb40";
    hash = "sha256-LvdT3YyPMJG3i3UZ1f9/9s3h1W6GLlm5JctLxwLXyXE=";
  }) + "/catppuccin-mocha/theme.toml";
in
{
  home.packages = with pkgs; [ ueberzugpp ];

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile."yazi/theme.toml".source = mochaTheme;
}

