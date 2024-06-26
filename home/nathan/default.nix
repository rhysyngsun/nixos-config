{
  inputs,
  outputs,
  nix-defaults,
}:
let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    inherit (nix-defaults.nixpkgs) config overlays;
  };
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
    {
      nix = {
        package = pkgs.nix;
        inherit (nix-defaults.nix) settings;
      };
    }
  ];

  inherit pkgs;

  extraSpecialArgs = {
    inherit system inputs;
  };
}
