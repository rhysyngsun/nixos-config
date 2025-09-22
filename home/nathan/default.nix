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
    inputs.nvf.homeManagerModules.default
    inputs.stylix.homeManagerModules.stylix
    # inputs.hyprland.homeManagerModules.default
    ({ modulesPath, ... }: {
      # Important! We disable home-manager's module to avoid option
      # definition collisions
      disabledModules = ["${modulesPath}/programs/anyrun.nix"];
    })
    inputs.anyrun.homeManagerModules.default
    inputs.ags.homeManagerModules.default
    inputs.catppuccin.homeModules.catppuccin
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
