{ inputs, outputs, ... }:
{

  mkSystem = { hostName, system, pkgs, lib, ... }: lib.nixosSystem {
    specialArgs = { inherit inputs outputs; };
    modules = [
      # > Our main nixos configuration file <
      ./configuration.nix
      ../modules
      ./home.nix
       inputs.home-manager.nixosModules.home-manager
      {
        imports = [
          ../hosts/${hostname}
        ];

        networking.hostName = "${hostName}";
      }
    ];
  };
}