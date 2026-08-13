# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{ inputs, ... }@top:
{
  flake.modules.nixos.host-lilith =
    {
      inputs,
      config,
      pkgs,
      ...
    }:
    {
      # You can import other NixOS modules here
      imports = [
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p1
        inputs.catppuccin.nixosModules.catppuccin
        inputs.nixos-hardware.nixosModules.common-gpu-nvidia

        ../../hosts/lilith/open-learning
        ../../hosts/lilith/hardware-configuration.nix
      ];

      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          waylandFrontend = true;
        };
      };

      services.dbus = {
        packages = with pkgs; [ blueman ];
      };

      boot.plymouth = {
        enable = true;
        themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
        theme = "catppuccin-mocha";
      };

      programs.xwayland.enable = true;

      services.flatpak.enable = true;

      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [ stdenv.cc.cc ];
      };

      programs.niri.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          kdePackages.xdg-desktop-portal-kde
          xdg-desktop-portal-gtk
        ];
        wlr.enable = true;
      };

      # file manager
      programs.thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-archive-plugin
          thunar-dropbox-plugin
          thunar-media-tags-plugin
          thunar-volman
        ];
      };
      services.gvfs.enable = true; # Mount, trash, and other functionalities
      services.tumbler.enable = true; # Thumbnail support for images

      programs.wireshark.enable = true;
      programs.steam.enable = true;

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        LIBVA_DRIVER_NAME = "nvidia";
        XDG_SESSION_TYPE = "wayland";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };

      environment.systemPackages = with pkgs; [
        libxcrypt
        openssl
        vulkan-tools
        wireplumber
        mesa-demos

        wineWow64Packages.stable

        lshw
        nvtopPackages.full

        dig

        # Theme
        (catppuccin-kde.override {
          flavour = [ "mocha" ];
          accents = [ "lavender" ];
        })

        # Cursor
        catppuccin-cursors

        # SDDM theme
        catppuccin-sddm-corners
      ];

      networking = {
        hostName = "lilith";
        networkmanager = {
          enable = true;
        };
        nameservers = [
          "8.8.8.8"
          "8.8.4.4"
          "2001:4860:4860::8888"
          "2001:4860:4860::8844"
        ];
      };

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # enable audio
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };

      services.displayManager = {
        defaultSession = "plasma";
        sddm = {
          enable = true;
          wayland.enable = true;
          theme = "catppuccin-mocha";
        };
      };
      services.desktopManager.plasma6.enable = true;

      hardware.bluetooth.enable = true;
      services.blueman.enable = true;

      users = {
        defaultUserShell = pkgs.zsh;
        users = {
          nathan = {
            # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
            # Be sure to change it (using passwd) after rebooting!
            initialPassword = "correcthorsebatterystaple";
            isNormalUser = true;
            extraGroups = [
              "docker"
              "wheel"
              "input"
              "audio"
              "networkmanager"
            ];
          };
          rhysyngsun = {
            # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
            # Be sure to change it (using passwd) after rebooting!
            initialPassword = "correcthorsebatterystaple";
            isNormalUser = true;
            extraGroups = [
              "docker"
              "wheel"
              "input"
              "audio"
              "networkmanager"
            ];
          };
        };
      };

      fonts = {
        fontconfig.enable = true;
        fontDir.enable = true;
        packages = (map (f: f.package) (builtins.attrValues pkgs.rice.font)) ++ [
          pkgs.nerd-fonts.fira-code
          pkgs.nerd-fonts.fira-mono
          (pkgs.google-fonts.override {
            fonts = [
              "Expletus Sans"
            ];
          })
        ];
      };

      nixpkgs.config.allowUnfree = true;
      nix.settings.download-buffer-size = 524288000;

      security = {
        rtkit.enable = true;
      };

      virtualisation = {
        docker.enable = true;
      };

      programs.dconf.enable = true;

      # Shells
      programs.zsh.enable = true;
      environment.shells = with pkgs; [
        zsh
        bash
      ];

      # Enable CUPS to print documents
      services.printing.enable = true;
      services.printing.browsing = true;
      services.printing.browsedConf = ''
        BrowseDNSSDSubTypes _cups,_print
        BrowseLocalProtocols all
        BrowseRemoteProtocols all
        CreateIPPPrinterQueues All

        BrowseProtocols all
      '';
      services.avahi.enable = true;
      services.avahi.nssmdns4 = true;
      services.avahi.openFirewall = true;

      # timezone
      services.localtimed.enable = true;
      services.automatic-timezoned.enable = true;
      location.provider = "geoclue2";

      # Video support
      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = with pkgs; [
            nvidia-vaapi-driver
            intel-media-driver
            libva-vdpau-driver
          ];
        };
        nvidia = {
          modesetting.enable = true;
          open = false;
          powerManagement.enable = true;
          powerManagement.finegrained = false;
          prime = {
            intelBusId = "PCI:0:2:0";
            nvidiaBusId = "PCI:1:0:0";
            offload.enable = false;
            sync.enable = true;
          };
        };
      };

      services.gnome.at-spi2-core.enable = true;

      services.devmon.enable = true;

      services.journald = {
        extraConfig = ''
          # 3 days
          MaxRetentionSec=259200
        '';
      };

      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      system.stateVersion = "24.11";
    };
}
