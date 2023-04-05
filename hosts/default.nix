{ inputs, outputs }:

let
  lib = inputs.nixpkgs.lib;
  mkSystem = hostName: lib.nixosSystem {
    specialArgs = {
      inherit inputs outputs;
    };
    modules = [
      # > Our main nixos configuration file <
      ../nixos/configuration.nix
      ./${hostName}
      inputs.hyprland.homeManagerModules.default
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.sharedModules = [
          outputs.homeManagerModules
        ];
        home-manager.users = {
          "nathan" = import ../users/nathan;
        };

        networking.hostName = "${hostName}";
      }
    ];
  };
in
{
  morrigan = mkSystem "morrigan";
}
