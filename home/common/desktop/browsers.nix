{ lib, pkgs, inputs, ... }:
with lib;
let
  addons = inputs.firefox-addons.packages.${pkgs.system};
in
{
  programs.firefox = {
    enable = true;

    profiles = {
      Default = {
        id = 0;
        isDefault = true;

        extensions = with addons; [
          # lastpass-password-manager
        ];

        settings = {
          "network.protocol-handler.expose.magnet" = true;
        };
      };
    };
  };
}
