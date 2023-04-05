{ pkgs, ... }:
{
  imports = [
    ./git
    ./nodejs
    ./zsh
  ];

  home = {
    packages = with pkgs; [
      gaphor

      hostctl
      http-prompt
      httpie
      jq
      just
      usql

      # virtualization
      lazydocker
      vagrant
    ];
  };
}
