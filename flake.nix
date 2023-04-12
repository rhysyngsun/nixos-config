{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprpaper.url = "github:hyprwm/hyprpaper";

    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-rice = { url = "github:bertof/nix-rice"; };

    networkmanager-dmenu = {
      url = "github:firecat53/networkmanager-dmenu";
      flake = false;
    };

    catppuccin-hyprland = {
      url = "github:catppuccin/hyprland";
      flake = false;
    };

    catppcuccin-rofi = {
      url = "github:catppuccin/rofi";
      flake = false;
    };

    catppuccin-waybar = {
      url = "github:catppuccin/waybar";
      flake = false;
    };
    

    nvchad = {
      url = "github:nvchad/nvchad";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, hyprland, home-manager, nix-rice, ... }@inputs:
    let
      inherit (self) outputs;

      nix-defaults = {
        nix = import ./nix-settings.nix {
          inherit inputs;
          inherit (nixpkgs) lib;
        };
        nixpkgs = {
          overlays = [
            outputs.overlays.additions
            outputs.overlays.modifications
            outputs.overlays.unstable-packages
            # overlays from inputs
            hyprland.overlays.default
            nix-rice.overlays.default
          ];
          config = {
            allowUnfree = true;
          };
        };
      };

      forEachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" ];
      forEachPkgs = f: forEachSystem (sys: f nixpkgs.legacyPackages.${sys});
    in
    rec {
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;

      # Devshell for bootstrapping
      # Acessible through 'nix develop'
      devShells = forEachPkgs (pkgs: import ./shell.nix { inherit pkgs; });

      formatter = forEachPkgs (pkgs: pkgs.nixpkgs-fmt);

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        morrigan = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/morrigan/configuration.nix
            nix-defaults
          ];
        };
      };

      homeConfigurations = {
        nathan = home-manager.lib.homeManagerConfiguration (
          import ./home/nathan {
            inherit inputs outputs nix-defaults;
          }
        );
      };
    };
}
