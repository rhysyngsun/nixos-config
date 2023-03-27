{ pkgs, inputs, ... }:

let
  addons = inputs.firefox-addons.packages.${pkgs.system};
in {
  programs.firefox = {
    enable = true;

    profiles = {
      Default = {
        id = 1;
        isDefault = true;

        extensions = with addons; [
          lastpass-password-manager
        ];
      };
    };
  };
}