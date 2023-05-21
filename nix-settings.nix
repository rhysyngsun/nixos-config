{ inputs, lib, ... }:

let
  # This will add each flake input as a registry
  # To make nix3 commands consistent with your flake
  registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
in
{
  inherit registry;

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  # nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") registry;

  settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes";
    # Deduplicate and optimize nix store
    auto-optimise-store = true;
    allowed-users = [ "root" "nathan" ];

    # add binary caches
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
    substituters = [
      "https://cache.nixos.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://hyprland.cachix.org"
    ];
  };

  gc = {
    # automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # extraOptions = ''
  #   plugin-files = ${pkgs.nix-doc}/lib/libnix_doc_plugin.so
  # '';
}
