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
    inputs.hyprland.homeManagerModules.default
    inputs.anyrun.homeManagerModules.default
    outputs.homeManagerModules
    ./home.nix
    ../common
  ];
  pkgs = import inputs.nixpkgs {
    inherit system;
    inherit (nix-defaults.nixpkgs) config overlays;
  };

  extraSpecialArgs = { inherit system inputs; };
}
