{ ... }:
let
  username = "nathan";
in
{
  imports = [
    ./myco.nix
  ];

  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";
    stateVersion = "22.05";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  i18n.inputMethod.enabled = "fcitx5";

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

}
