{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
 
    hyprland.url = "github:hyprwm/Hyprland";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
      forEachPkgs = f: forEachSystem (sys: f nixpkgs.legacyPackages.${sys});
      inherit (self) outputs;
    in 
    rec {
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;
      # Devshell for bootstrapping
      # Acessible through 'nix develop'
      devShells = forEachPkgs(pkgs: import ./shell.nix { inherit pkgs; });
      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      
      packages = forEachPkgs(pkgs: import ./pkgs { inherit pkgs; });

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = import ./hosts {
        inherit inputs outputs;
      };
    };
}
