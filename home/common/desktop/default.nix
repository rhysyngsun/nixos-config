{ pkgs, config, ... }:
{
  imports = [
    # ./bin.nix
    ./browsers.nix
    ./hyprland
    ./wayland
  ];
  home = {
    packages = with pkgs; [
      xfce.thunar
      unstable.obsidian
      libsForQt5.kcharselect
      pavucontrol
      wtf
      # xplr
      discord
      slack
      zoom-us
      file
      exiftool
      xdg-utils

      thunderbird

      baobab

      playerctl
      nuclear
      dropbox
      vlc

      keybase-gui
    ];

    sessionVariables =
      let
        editor = "nvim";
      in
      {
        EDITOR = editor;
        VISUAL = editor;
        GIT_EDITOR = editor;

        SHELL = "${pkgs.zsh}/bin/zsh";
      };
  };

  programs = {
    alacritty = {
      enable = true;
      settings = {
        font = {
          family = pkgs.rice.font.monospace.name;
        };
        window = {
          padding = {
            x = 8;
            y = 8;
          };
        };
        shell.program = config.home.sessionVariables.SHELL;
      };
    };

    broot = {
      enable = true;
      enableZshIntegration = true;
    };

    btop = {
      enable = true;
      settings = {
        color_theme = "catppuccin_mocha";
      };
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;

      nix-direnv.enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    go = {
      enable = true;
      packages = {
        "github.com/danielgtaylor/restish" = builtins.fetchGit {
          url = "https://github.com/danielgtaylor/restish";
          rev = "ee2e1ae6cbd6ae2f96b7b4ab3e277e926d224701";
        };
        "github.com/shihanng/gig" = builtins.fetchGit {
          url = "https://github.com/shihanng/gig";
          rev = "52dadde2b1d858ede8a1f46da29bceec1e8bfe75";
        };
      };
    };

    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    pls = {
      enable = true;
      enableAliases = true;
    };

    vscode = {
      enable = true;
      extensions = with pkgs.unstable.vscode-extensions ; [
        # nix
        bbenoist.nix
        jnoortheen.nix-ide

        # configuration languages
        bungcip.better-toml
        redhat.vscode-yaml
      ];
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };

  xdg.configFile."btop/themes" = {
    source = pkgs.rice.btop.package;
    recursive = true;
  };

  # services
  services = {
    kbfs.enable = true;
    keybase.enable = true;
    mpd.enable = true;
  };
}
