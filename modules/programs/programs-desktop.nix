{ ... }:
{
  flake.modules.homeManager.programs-desktop =
    {
      lib,
      pkgs,
      ...
    }:
    with lib;
    {
      home = {
        packages = with pkgs; [
          networkmanagerapplet
          pavucontrol
          crosspipe
          qpwgraph
          unetbootin
          wtfutil
          lsof
          file
          nnn
          exiftool
          xdg-utils
          unzip
          zlib
          gnome-calendar
          nemo-with-extensions
          cosmic-edit
          simple-scan
          gpu-viewer
          woeusb

          qownnotes

          baobab

          playerctl
          pamixer
          nuclear
          dropbox
          vlc
          coreutils-full
          less

          keybase-gui

          gimp-with-plugins

          loupe
          inkscape-with-extensions
          shotwell
          ffmpeg

          libreoffice-qt
          hunspell
          hunspellDicts.en_US

          blender
          yt-dlp

          prismlauncher

          libxcrypt

          glade

          obsidian
          texliveFull
        ];

        sessionVariables =
          let
            editor = "nvim";
          in
          {
            EDITOR = editor;
            VISUAL = editor;
            GIT_EDITOR = editor;

            BROWSER = "firefox";
          };
      };

      catppuccin = {
        accent = "lavender";
        flavor = "mocha";
        btop.enable = true;
        rofi.enable = true;
      };

      programs = {
        bash.enable = true;
        broot = {
          enable = true;
          enableZshIntegration = true;
        };

        btop = {
          enable = true;
          settings = {
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
          historyWidget.command = "";
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

      # services
      services = {
        blueman-applet.enable = true;
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
    };
}
