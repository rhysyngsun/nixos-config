# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, outputs, lib, config, pkgs, ... }: {
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

  programs.hyprland.enable = true;

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

  environment.systemPackages = with pkgs; [
    # nix-doc
    libxcrypt
    openssl
    v4l-utils
    wireplumber
  ];

  networking = {
    hostName = "morrigan";
    networkmanager = {
      enable = true;
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # enable loopback webcam in kernel
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];

  # enable audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };
  environment.etc."wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
		bluez_monitor.properties = {
			["bluez5.enable-sbc-xq"] = true,
			["bluez5.enable-msbc"] = true,
			["bluez5.enable-hw-volume"] = true,
			["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
		}
	'';

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

  fonts = {
    fontconfig.enable = true;
    fontDir.enable = true;
    fonts = map (f: f.package) (builtins.attrValues pkgs.rice.font);
  };

  programs.sway.enable = true;

  security.pam.services.swaylock.text = "auth include login";

  virtualisation = {
    docker.enable = true;
    virtualbox.host.enable = true;
  };

  programs.dconf.enable = true;

  # Shells
  programs.zsh.enable = true;
  environment.shells = with pkgs; [ zsh bash ];

  # Enable CUPS to print documents
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  services.avahi.openFirewall = true;

  # Enable sound
  sound.enable = false;
  hardware.pulseaudio.enable = false;

  # timezone
  services.localtimed.enable = true;
  services.automatic-timezoned.enable = true;
  location.provider = "geoclue2";

  # Video support
  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.driSupport = true;
  hardware.nvidia.modesetting.enable = true;

  services.gnome.at-spi2-core.enable = true;

  services.devmon.enable = true;

  services.journald = {
    extraConfig = ''
    # 3 days
    MaxRetentionSec=259200
    '';
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
