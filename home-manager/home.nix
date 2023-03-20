# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, outputs, lib, config, pkgs, ... }: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    ./zsh.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  home = {
    username = "nathan";
    homeDirectory = "/home/nathan";

    sessionVariables = rec {
      EDITOR = "nvim";
      VISUAL = EDITOR;
      GIT_EDITOR = EDITOR;
    };

    file."${config.xdg.configHome}" = {
      source = ./config;
      recursive = true;
    };

    shellAliases = import ./aliases.nix;
    packages = with pkgs; [
      # system-ish
      htop
      jdk
      man
      niv
      pstree
      starship
      tldr
      tree
      zsh

      # dev
      gita
      hostctl
      http-prompt
      httpie
      jq
      just
      lazydocker
      pre-commit
      usql
      vagrant

      # fonts
      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "FiraMono"
          "Iosevka"
        ];
      })
    ];
  };

  # Fonts
  fonts.fontconfig.enable = true;
  xdg.dataFile."fonts" = {
    source = ./fonts;
    recursive = true;
  };

  programs = {
    alacritty = {
      enable = true;
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

    firefox = {
      enable = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    git = {
      enable = true;

      delta = {
        enable = true;
      };

      includes = [
        { path = "~/.config/git/default.gitconfig"; }
        {
          path = "~/.config/git/ol.gitconfig";
          condition = "hasconfig:remote.*.url:https://github.com/mitodl/**";
        }
      ];
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
    polybar = {
      enable = true;
      package = pkgs.polybarFull;
      script = "polybar main &";
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  xdg.userDirs.enable = true;
  xdg.configFile."polybar".source = pkgs.symlinkJoin {
    name = "polybar-symlinks";
    paths =
      let
        polybar-themes = pkgs.fetchFromGitHub {
          owner = "adi1090x";
          repo = "polybar-themes";
          rev = "master"; # Or, better, use a specific commit so you don't have to update the sha256-hash all the time
          sha256 = "sha256-yOiPE12iKyJVUhB9XOzTUIFQgjT/psE1LRT0OjXWp8E="; # Fill this in with the hash that nix provides when you attempt to build your config using this
        };
      in
      [
        "${polybar-themes}/fonts"
        "${polybar-themes}/simple"
      ];
  };
  xsession.windowManager.bspwm = {
    enable = true;
    extraConfigEarly = ''
    #! /bin/sh
    #
    killall -9 sxhkd polybar

    # Set the number of workspaces
    bspc monitor -d 1 2 3 4 5 6

    # Launch keybindings daemon
    sxhkd &

    # Window configurations
    bspc config border_width         0
    bspc config window_gap           8
    bspc config split_ratio          0.5
    bspc config borderless_monocle   true
    bspc config gapless_monocle      true

    # Padding outside of the window
    bspc config top_padding            0
    bspc config bottom_padding         0
    bspc config left_padding           0
    bspc config right_padding          0

    # Move floating windows
    bspc config pointer_action1 move

    # Resize floating windows
    bspc config pointer_action2 resize_side
    bspc config pointer_action2 resize_corner

    # Set background and top bar
    #feh --bg-scale $HOME/.local/state/feh/active
    bash -c "$HOME/.config/polybar/launch.sh --docky &"

    sleep .25

    bspc rule -a Code desktop='^1' follow=on

    ${config.programs.alacritty.package}/bin/alacrity

    sleep .25

    bspc rule -a Code desktop='^3' follow=on
    
    '';
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
