# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, outputs, lib, config, pkgs, ... }: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example
    # outputs.nixosModules.themes.catppuccin

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default
    inputs.hyprland.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./bspwm.nix
    ./sxhkd.nix
    ./themes.nix
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

  i18n.inputMethod.enabled = "fcitx5";

  wayland.windowManager.hyprland = {
    enable = true;
    systemdIntegration = true;
    xwayland = {
      enable = true;
    };
  };

  home = {
    username = "nathan";
    homeDirectory = "/home/nathan";

    # activation = {
    #   reloadPolybar = lib.hm.dag.entryAfter ["writeBoundary"] ''
    #     $DRY_RUN_CMD ${pkgs.polybarFull}/bin/polybar-msg cmd restart
    #   '';
    # };

    sessionVariables = rec {
      EDITOR = "nvim";
      VISUAL = EDITOR;
      GIT_EDITOR = EDITOR;

      SHELL = "${pkgs.zsh}/bin/zsh";
    };

    file."${config.xdg.configHome}" = {
      source = ./config;
      recursive = true;
    };

    pointerCursor = {
      x11.enable = true;
      gtk.enable = true;
    };

    shellAliases = import ./aliases.nix;
    packages = with pkgs; [
      # user
      # libsForQt5.kcharselect
      # libsForQt5.pix

      # xfce.thunar
      wofi
      swaybg
      wlsunset
      wl-clipboard

      # pkgs.unstable.obsidian
      # wtf
      # xplr

      # system-ish
      # coreutils-full
      # cht-sh
      # htop
      # jdk
      # killall
      # ntfy
      # man
      # niv
      # polybarFull
      # pstree
      # starship
      # tldr
      # tree

      # dev
      # ffmpeg
      # gita
      # hostctl
      # http-prompt
      # httpie
      # jq
      # just
      # lazydocker
      # pre-commit
      # usql
      # vagrant

      # chats
      # discord
      # slack
    ];
  };

  # https://pixabay.com/id/videos/garis-biru-latar-belakang-abstrak-4967/
  
  # Fonts
  fonts.fontconfig.enable = true;
  xdg.dataFile."fonts" = {
    source = ./fonts;
    recursive = true;
  };

  # programs = {
  #   alacritty = {
  #     enable = true;
  #     settings = {
  #       window = {
  #         padding = {
  #           x = 8;
  #           y = 8;
  #         };
  #       };
  #       shell.program = config.home.sessionVariables.SHELL;
  #     };
  #   };

  #   broot = {
  #     enable = true;
  #     enableZshIntegration = true;
  #   };

  #   btop.enable = true;

  #   direnv = {
  #     enable = true;
  #     enableBashIntegration = true;
  #     enableZshIntegration = true;

  #     nix-direnv.enable = true;
  #   };

  #   firefox = {
  #     enable = true;
  #   };

  #   fzf = {
  #     enable = true;
  #     enableZshIntegration = true;
  #   };

  #   git = {
  #     enable = true;

  #     delta = {
  #       enable = true;
  #     };

  #     includes = [
  #       { path = "${config.xdg.configHome}/git/default.gitconfig"; }
  #       {
  #         path = "${config.xdg.configHome}/git/ol.gitconfig";
  #         condition = "hasconfig:remote.*.url:https://github.com/mitodl/**";
  #       }
  #     ];
  #   };

  #   go = {
  #     enable = true;
  #     packages = {
  #       "github.com/danielgtaylor/restish" = builtins.fetchGit {
  #         url = "https://github.com/danielgtaylor/restish";
  #         rev = "ee2e1ae6cbd6ae2f96b7b4ab3e277e926d224701";
  #       };
  #       "github.com/shihanng/gig" = builtins.fetchGit {
  #         url = "https://github.com/shihanng/gig";
  #         rev = "52dadde2b1d858ede8a1f46da29bceec1e8bfe75";
  #       };
  #     };
  #   };

  #   # Let Home Manager install and manage itself.
  #   home-manager.enable = true;

  #   neovim = {
  #     enable = true;
  #     vimAlias = true;
  #     plugins = with pkgs.vimPlugins; [
  #       auto-pairs
  #       fzf-vim
  #       lightline-vim
  #       nerdtree

  #       vim-polyglot
  #       vim-gitgutter
  #       vim-nix
  #     ];
  #   };

  #   pls = {
  #     enable = true;
  #     enableAliases = true;
  #   };

  #   rofi.enable = true;

  #   vscode = {
  #     enable = true;
  #     extensions = with pkgs.unstable.vscode-extensions ; [
  #       # nix
  #       bbenoist.nix
  #       jnoortheen.nix-ide

  #       # configuration languages
  #       bungcip.better-toml
  #       redhat.vscode-yaml
  #     ];
  #   };

  #   zoxide = {
  #     enable = true;
  #     enableBashIntegration = true;
  #     enableZshIntegration = true;
  #   };
  # };
  # services
  # services = {
  #   flameshot = { 
  #     enable = true;
  #     settings = {
  #       General = {
  #         savePath = "${config.home.homeDirectory}/Pictures/Screenshots";
  #       };
  #     };
  #   };
  #   keybase.enable = true;
  #   mpd.enable = true;
  # };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    extraConfig = {
      XDG_SCREENSHOTS_DIR = "$XDG_PICTURES_DIR/Screenshots";
    };
  };

  xsession = {
    enable = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
