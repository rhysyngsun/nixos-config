# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, outputs, lib, config, pkgs, ... }: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.themes.catppuccin

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd
    inputs.hyprland.nixosModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
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
    };
  };

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    extraOptions = ''
      plugin-files = ${pkgs.nix-doc}/lib/libnix_doc_plugin.so
    '';
  };

  i18n.inputMethod.enabled = "fcitx5";

  #programs.hyprland.enable = true;

  environment.systemPackages = with pkgs; [
    # nix-doc
    # gvfs
  ];

  networking.hostName = "gaea";
  
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
    # useOSProber = true;
  };

  # enable audio
  services.pipewire = {
    enable = false;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

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
          "vboxsf"
        ];
      };
    };
  };

  
  # display
  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "";
    screenSection = ''
      Option       "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
      Option       "AllowIndirectGLXProtocol" "off"
      Option       "TripleBuffer" "on"
    '';

    displayManager = {
      sddm.enable = true;
      # defaultSession = "none+bspwm";
      # lightdm = {
      #   enable = true;
      #   background = ../backgrounds/the_valley.png;
      #   greeters.gtk = let
      #     flavor = "Mocha";
      #     accent = "Lavender";
      #     flavorLower = lib.toLower flavor;
      #     accentLower = lib.toLower accent;
      #   in {
      #     enable = true;
      #     theme = {
      #       name = "Catppuccin-${flavor}-Compact-${accent}-Dark";
      #       package = pkgs.unstable.catppuccin-gtk.override {
      #         accents = [ accentLower ];
      #         size = "compact";
      #         tweaks = [ "rimless" "black" ];
      #         variant = flavorLower;
      #       };
      #     };
      #   };
      # };
    };

    windowManager.bspwm = {
      enable = true;
    };
  };

  fonts = {
    fontconfig.enable = true;
    fontDir.enable = true;
    fonts = with pkgs; [
      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "FiraMono"
          "Iosevka"
        ];
      })
    ];
  };

  programs.dconf.enable = true;

  # Shells
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh bash ];

  # Enable CUPS to print documents
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.brlaser ];

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Video support
  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.driSupport = true;
  hardware.nvidia.modesetting.enable = true;

  virtualisation.virtualbox.guest.enable = true;
  #virtualisation.virtualbox.guest.x11 = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
