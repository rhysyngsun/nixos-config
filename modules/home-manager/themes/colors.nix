{ config, lib, ... }:
with lib;
let
  cfg = config.themes.colors;
in
{
  options.themes.colors = {

    flavor = {
      name = mkOption {
        description = "Catppuccin flavor.";
        type = types.str;
        default = "Mocha";
      };
      lower = toLower cfg.flavor.name;
    };
    accent = {
      name = mkOption {
        description = "Catppuccin accent.";
        type = types.str;
        default = "Lavender";
      };
      lower = toLower cfg.accent.name;
    };
  };
}