{ inputs, pkgs, ... }:
{

  programs.waybar = {
    enable = true;

    style = import ./style.nix { inherit inputs; };
    settings = import ./settings.nix { inherit pkgs; };
  };
}
