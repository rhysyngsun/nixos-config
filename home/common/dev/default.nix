{ pkgs, ... }:
{
  imports = [
    ./git
    ./neovim.nix
    ./nodejs
    # ./ol-local
    ./python
    ./tmux.nix
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

  programs.vscode.userSettings = {
    "editor.formatOnType" = true;
  };
}
