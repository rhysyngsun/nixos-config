{ inputs
, outputs
, nix-defaults
,
}:
let
  system = "x86_64-linux";
in
{
  modules = [
    inputs.anyrun.homeManagerModules.default
    inputs.nixvim.homeManagerModules.nixvim
    inputs.stylix.homeManagerModules.stylix
    inputs.ags.homeManagerModules.default
    outputs.homeManagerModules
    ./home.nix
    ../../themes/stylix.nix
    ../common
  ];
  pkgs = import inputs.nixpkgs-unstable {
    inherit system;
    inherit (nix-defaults.nixpkgs) config overlays;
  };

  extraSpecialArgs = {
    inherit system inputs;
    pkgs-stable = import inputs.nixpkgs {
      inherit system;
      inherit (nix-defaults.nixpkgs) config overlays;
    };
  };
}
