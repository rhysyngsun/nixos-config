{ inputs, outputs }:

let
  lib = inputs.nixpkgs.lib;
  mkSystem =
    hostName:
    lib.nixosSystem {
      specialArgs = {
        inherit inputs outputs;
      };
      modules = [
        # > Our main nixos configuration file <
        ../nixos/configuration.nix
        ../themes/stylix.nix
        ./${hostName}
        inputs.stylix.nixosModules.stylix
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = [ ../home/common ];
          home-manager.users = {
            "nathan" = import ../home/nathan;
          };

          networking.hostName = "${hostName}";
        }
      ];
    };
in
{
  morrigan = mkSystem "morrigan";
}
