{
  description = "Rhysyngsun's nixos configs";

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      home-manager,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      nix-defaults = {
        nix = import ./nix-settings.nix {
          inherit inputs;
          inherit (nixpkgs) lib;
        };
        nixpkgs = {
          overlays = [
            # overlays from inputs
            inputs.nix-rice.overlays.default
            inputs.copier.overlays.default
            # hyprland 
            inputs.hyprcursor.overlays.default
            # from flake outputs
            outputs.overlays.additions
            outputs.overlays.modifications
            #outputs.overlays.unstable-packages
          ];
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [ "electron-25.9.0" ];
          };
        };
      };

      forEachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" ];
      forEachPkgs = f: forEachSystem (sys: f nixpkgs.legacyPackages.${sys});

      # Eval the treefmt modules from ./treefmt.nix
      treefmtEval = forEachPkgs (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;

      # Devshell for bootstrapping
      # Acessible through 'nix develop'
      devShells = forEachPkgs (pkgs: import ./shell.nix { inherit pkgs; });

      formatter = forEachPkgs (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

      checks = forEachPkgs (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        morrigan = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
          };
          modules = [
            inputs.sops-nix.nixosModules.sops
            # keyboard remapper
            inputs.xremap-flake.nixosModules.default

            nix-defaults

            ./hosts/morrigan/configuration.nix
          ];
        };
      };

      homeConfigurations = {
        nathan =
          home-manager.lib.homeManagerConfiguration (
            import ./home/nathan { inherit inputs outputs nix-defaults; }
          )
          // {
            nixpkgs.config = nix-defaults.nixpkgs.config;
          };
      };
    };

  inputs = {
    # Nixpkgs
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixpkgs-unstable";
    # nixpkgs.follows = "nixpkgs-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    # home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";

    sops-nix.url = "github:Mic92/sops-nix";

    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  inputs = {
    hyprland.url = "github:hyprwm/Hyprland?ref=v0.40.0";

    hycov = {
      url = "github:DreamMaoMao/hycov";
      inputs.hyprland.follows = "hyprland";
    };

    hy3 = {
      url = "github:outfoxxed/hy3?ref=hl0.40.0";
      # or "github:outfoxxed/hy3" to follow the development branch.
      # (you may encounter issues if you dont do the same for hyprland)
      inputs.hyprland.follows = "hyprland";
    };

    hyprpicker.url = "github:hyprwm/hyprpicker";
    hyprcursor.url = "github:hyprwm/hyprcursor";

    xremap-flake.url = "github:xremap/nix-flake";
  };

  inputs = {
    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";

    anyrun = {
      url = "github:Kirottu/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags.url = "github:Aylur/ags";

    wezterm.url = "github:wez/wezterm?dir=nix";

    copier.url = "github:copier-org/copier";

    networkmanager-dmenu = {
      url = "github:firecat53/networkmanager-dmenu";
      flake = false;
    };
  };

  # rice
  inputs = {
    stylix.url = "github:danth/stylix";

    nix-rice.url = "github:bertof/nix-rice";

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

    devenv = {
      url = "github:cachix/devenv/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:nix-community/nixvim";

    mach-nix.url = "github:DavHau/mach-nix";
  };
}
