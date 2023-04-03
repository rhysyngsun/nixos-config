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
      ../home
      ./${hostName}
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;

        networking.hostName = "${hostName}";
      }
    ];
  };
in {
  morrigan = mkSystem "morrigan";
}