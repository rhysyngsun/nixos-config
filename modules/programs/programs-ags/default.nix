{ ... }:
{
  flake.modules.homeManager.programs-ags =
    { config, ... }:
    {
      programs.ags = {
        enable = true;
        configDir = config.lib.file.mkOutOfStoreSymlink "/home/nathan/nixos/modules/programs/programs-ags/_config/";
        # configDir = ./_config;
      };
    };
}
