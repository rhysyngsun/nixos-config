{ lib, pkgs, ... }:
with lib;
{
  imports = [
    # ./bin.nix
    ./ags
    ./browsers.nix
    ./calendar.nix
    ./chat.nix
    # ./eww
    ./hyprland
    ./pls.nix
    # ./productivity.nix
    ./wayland
  ];
  home = {
    packages = with pkgs; [
      #libsForQt5.kcharselect
      networkmanagerapplet
      pavucontrol
      helvum
      qpwgraph
      unetbootin
      wtf
      file
      nnn
      exiftool
      xdg-utils
      unzip
      zlib
      gnome-calendar
      mkchromecast
      nemo-with-extensions
      cosmic-edit
      simple-scan

      qownnotes

      baobab

      playerctl
      pamixer
      nuclear
      dropbox
      vlc
      coreutils-full
      less
      pulseaudio

      keybase-gui

      gimp
      inkscape-with-extensions
      shotwell
      ffmpeg

      # libreoffice-qt
      hunspell
      hunspellDicts.en_US

      # transmission_4-gtk

      blender

      prismlauncher

      # pants
      libxcrypt

      glade

      obsidian
    ];

    sessionVariables =
      let
        editor = "nvim";
      in
      {
        EDITOR = editor;
        VISUAL = editor;
        GIT_EDITOR = editor;

        # SHELL = "${pkgs.zsh}/bin/zsh";
      };
  };

  programs = {
    broot = {
      enable = true;
      enableZshIntegration = true;
    };

    btop = {
      enable = true;
      settings = {
        color_theme = "catppuccin_mocha";
        theme_background = false;
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

    krita = {
      enable = true;
      plugins = with pkgs.krita-plugins; [
        buli-brush-switch
        compact-brush-toggler
        shapes-and-layers
        shortcut-composer
        subwindow-organizer
        ui-redesign
      ];
    };

    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-pipewire-audio-capture
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

  # xdg.configFile."easyeffects" = {
  #   source = pkgs.symlinkJoin {
  #     name = "easyeffects-plugins";
  #     paths = [
  #       pkgs.easyeffects-presets.jackhack96
  #       pkgs.easyeffects-presets.p-chan5
  #     ];
  #   };
  #   recursive = true;
  # };

  # services
  services = {
    blueman-applet.enable = true;
    # easyeffects = {
    #   enable = true;
    #   preset = "";
    # };
    kbfs.enable = true;
    keybase.enable = true;
    mpd.enable = true;
    network-manager-applet.enable = true;
  };

  # patch for wayland because it's not x11
  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      Wants = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
