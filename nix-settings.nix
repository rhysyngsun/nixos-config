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
  };

  gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # extraOptions = ''
  #   plugin-files = ${pkgs.nix-doc}/lib/libnix_doc_plugin.so
  # '';
}
