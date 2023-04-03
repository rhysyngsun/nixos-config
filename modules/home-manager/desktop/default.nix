{ pkgs, config, ... }:
{
  imports = [
    ./browsers.nix
    ./hyprland
    ./wayland
  ];
  
  config = {
    home = {
      packages = with pkgs; [
        pkgs.unstable.obsidian
        wtf
        # xplr
        discord
        slack
      ];

      sessionVariables = rec {
        EDITOR = "nvim";
        VISUAL = EDITOR;
        GIT_EDITOR = EDITOR;

        SHELL = "${pkgs.zsh}/bin/zsh";
      };
    };

    programs = {
      alacritty = {
        enable = true;
        settings = {
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

      btop.enable = true;

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

      neovim = {
        enable = true;
        vimAlias = true;
        plugins = with pkgs.vimPlugins; [
          auto-pairs
          fzf-vim
          lightline-vim
          nerdtree

          vim-polyglot
          vim-gitgutter
          vim-nix
        ];
      };

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

    # services
    services = {
      keybase.enable = true;
      mpd.enable = true;
    };
  };
}