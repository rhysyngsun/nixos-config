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
    extraConfig = ''
    
    # See https://wiki.hyprland.org/Configuring/Monitors/
    monitor=,preferred,auto,auto
    
    input {
      kb_layout = us
    
      follow_mouse = 1
      touchpad = {
        natural_scroll = false
      }
    }
    
    exec-once = firefox & alacritty

    bind=SUPER,RETURN,exec,${config.programs.alacritty.package}/bin/alacritty
    bind=SUPER,F,exec,${config.programs.firefox.package}/bin/firefox
    bind=SUPER,D,exec,${pkgs.wofi}/bin/wofi --show drun -I
    '';
    xwayland = {
      enable = true;
    };
  };

  home = {
    username = "nathan";
    homeDirectory = "/home/nathan";

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
      coreutils-full
      # cht-sh
      htop
      # jdk
      killall
      # ntfy
      # man
      # niv
      # polybarFull
      pstree
      starship
      tldr
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
      slack
    ];
  };

  # https://pixabay.com/id/videos/garis-biru-latar-belakang-abstrak-4967/
  
  # Fonts
  fonts.fontconfig.enable = true;
  xdg.dataFile."fonts" = {
    source = ./fonts;
    recursive = true;
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
        { path = "${config.xdg.configHome}/git/default.gitconfig"; }
        {
          path = "${config.xdg.configHome}/git/ol.gitconfig";
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

    rofi.enable = true;

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

    waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          modules-left = [ "clock" "cpu" "memory" "disk" ];
          modules-center = [ "wlr/workspaces" ];
          modules-right = [
            "temperature"
            "network"
            "pulseaudio"
            "battery"
            "tray"
          ];

          "wlr/workspaces" = {
            format = "{icon}";
            all-outputs = true;
            format-icons = {
              "1" = "";
              "2" = "";
              "3" = "";
              "4" = "";
            };
          };

          "cpu" = {
            interval = 10;
            format = " {usage}%";
            tooltip = false;
          };
          "memory" = {
            interval = 10;
            format = " {}%";
          };
          "disk" = {
            interval = 600;
            format = " {percentage_used}%";
            path = "/";
          };
          "clock" = {
            interval = 60;
            format = "{: %a %b %e %H:%M}";
          };
          "temperature" = {
            interval = 5;
            critical-threshold = 60;
            format = " {temperatureC}°C";
          };
          "network" = {
            format-wifi = " {signalStrength}%";
            format-ethernet = "";
            tooltip-format = "{ifname} via {gwaddr}";
            format-linked = "{ifname} (No IP)";
            format-disconnected = "";
          };
          "pulseaudio" = {
            format = "{icon} {volume}% {format_source}";
            format-muted = " {format_source}";
            format-source = "";
            format-source-muted = "";
            format-icons = { "default" = [ "" "" "" ]; };
            scroll-step = 1;
            tooltip-format = "{desc}; {volume}%";
            on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
            on-click-right = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
            on-click-middle = "pavucontrol";
          };
          "battery" = {
            interval = 60;
            states = {
              warning = 20;
              critical = 10;
            };
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% ";
            format-icons = [ "" "" "" "" ];
            format-alt = "{time} {icon}";
          };
          "tray" = { spacing = 10; };
        };
      };
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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
