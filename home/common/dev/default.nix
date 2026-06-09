{pkgs, inputs, ...}: {
  imports = [
    ./ai.nix
    ./aliases.nix
    ./git.nix
    ./godot
    # ./nodejs
    ./tmux.nix
    ./vscode.nix
    ./wezterm
    ./yazi.nix
    ./zsh
  ];

  home = {
    packages = with pkgs; [
      unstable.heroku
      xh
      just
      usql
      gnumake
      git-ignore
      lazygit
      entr
      tealdeer
      libtree
      squirrel-sql

      # http request cli's
      httpie
      unstable.posting

      # jq/xq/yq all-in-one
      yq-go
      jq

      sphinx

      cachix

      kubectl
      headlamp
      kubernetes-helm
      awscli2
      k6

      # virtualization
      lazydocker
      vagrant

      bytecode-viewer

      # concourse cli
      fly

      (inputs.nvf.lib.neovimConfiguration {
        pkgs = pkgs.nixos-master;

        modules = [
          {
            _module.args = {
              pkgs-stable = pkgs;
            };
          }
          ../../../modules/nvf
          ../../../nvf
        ];
      }).neovim
    ];
    sessionPath = ["$HOME/bin"];
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      "rm" = "rm -I --preserve-root";
    };
  };

  home.file.".cargo/config.toml".text = ''
    [net]
    git-fetch-with-cli = true
  '';
}
