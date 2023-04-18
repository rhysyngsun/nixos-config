{ pkgs, ... }:
{
  imports = [
    ./git
    ./neovim.nix
    ./nodejs
    ./python
    ./zsh
  ];

  home = {
    packages = with pkgs; [
      gaphor

      heroku
      http-prompt
      httpie
      jq
      just
      usql

      nnn

      # virtualization
      lazydocker
      vagrant
    ];
  };
}
