{ config, ... }: {
  programs.ags = {
    enable = true;
    configDir = config.lib.file.mkOutOfStoreSymlink "/home/nathan/.config/nixos/home/common/desktop/ags/_config/";
    # configDir = ./_config;
  };
}
