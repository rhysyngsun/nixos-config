# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{
  inputs,
  config,
  pkgs,
  ...
}:
{
  # You can import other NixOS modules here
  imports = [
    # outputs.nixosModules
    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd
    inputs.hyprland.nixosModules.default

    ./services
    ./open-learning
    ./hardware-configuration.nix
  ];

  i18n.inputMethod.enabled = "fcitx5";

  services.dbus = {
    packages = with pkgs; [ blueman ];
  };

  boot.plymouth = {
    enable = true;
    themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
    theme = "catppuccin-mocha";
  };

  programs.nix-ld.enable = true;

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  # file manager
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-dropbox-plugin
      thunar-media-tags-plugin
      thunar-volman
    ];
  };
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images

  programs.wireshark.enable = true;

  environment.systemPackages = with pkgs; [
    # nix-doc
    libxcrypt
    mesa.drivers
    openssl
    v4l-utils
    vulkan-tools
    wireplumber

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
    hostName = "morrigan";
    networkmanager = {
      enable = true;
    };
    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
    ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # enable loopback webcam in kernel
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # enable audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };
  # NOTE: these settings override the entire `bluez_monitor.properties` value,
  # so we need to redefine all the defaults
  environment.etc."wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
    bluez_monitor.enabled = true
    bluez_monitor.properties = {
      ["bluez5.enable-sbc-xq"] = true,
      ["bluez5.enable-msbc"] = true,
      ["bluez5.enable-hw-volume"] = true,
      ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]",
      ["bluez5.codecs"] = "[ sbc sbc_xq aac ]",
      ["bluez5.hfphsp-backend"] = "native",
      ["bluez5.default.rate"] = 48000,
      ["bluez5.default.channels"] = 2
    }
  '';

  services.displayManager = {
    defaultSession = "hyprland";
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "catppuccin-mocha";
    };
  };

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
    };
  };
  services.xremap = {
    enable = true;
    withHypr = true;
    config.keymap = [
      {
        name = "Print Screen";
        remap = {
          KEY_INSERT = "KEY_PRINT";
        };
      }
    ];
  };

  fonts = {
    fontconfig.enable = true;
    fontDir.enable = true;
    packages = map (f: f.package) (builtins.attrValues pkgs.rice.font);
  };

  security = {
    rtkit.enable = true;

    pam.services = {
      hyprlock = { };
    };
  };

  virtualisation = {
    docker.enable = true;
    virtualbox.host.enable = true;
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

  # Enable sound
  sound.enable = false;
  hardware.pulseaudio.enable = false;

  # timezone
  services.localtimed.enable = true;
  services.automatic-timezoned.enable = true;
  location.provider = "geoclue2";

  # Video support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia.modesetting.enable = true;

  services.gnome.at-spi2-core.enable = true;

  services.devmon.enable = true;

  # services.dnsmasq = {
  #   enable = true;
  #   extraConfig = ''
  #     address=/odl.local/172.28.0.1
  #   '';
  # };

  services.journald = {
    extraConfig = ''
      # 3 days
      MaxRetentionSec=259200
    '';
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
