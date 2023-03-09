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

    file.".config/starship.toml".source = ./config/starship.toml;
    file.".gitconfig".source = ./config/gitconfig;

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
      (nerdfonts.override { fonts = [ "FiraCode" "FiraMono" ]; })
    ];
  };

  # Fonts
  fonts.fontconfig.enable = true;

  programs = {
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

    git = {
      enable = true;

      delta = {
        enable = true;
      };
    };

    go = {
      enable = true;
      packages = {
        "github.com/danielgtaylor/restish" = builtins.fetchGit "https://github.com/danielgtaylor/restish";
        "github.com/shihanng/gig" = builtins.fetchGit "https://github.com/shihanng/gig";
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
  services.keybase.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
