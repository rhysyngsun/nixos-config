{
  description = "Rhysyngsun's nixos configs";

  outputs = {
    self,
    nixpkgs,
    treefmt-nix,
    home-manager,
    ...
  } @ inputs: let
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
          # inputs.copier.overlays.default
          inputs.nur.overlays.default
          # from flake outputs
          outputs.overlays.additions
          outputs.overlays.modifications
          outputs.overlays.unstable-packages
        ];
        config = {
          allowUnfree = true;
        };
      };
    };

    forEachSystem = nixpkgs.lib.genAttrs ["x86_64-linux"];
    forEachPkgs = f: forEachSystem (sys: f nixpkgs.legacyPackages.${sys});

    # Eval the treefmt modules from ./treefmt.nix
    treefmtEval = forEachPkgs (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
  in {
    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    # Devshell for bootstrapping
    # Acessible through 'nix develop'
    devShells = forEachPkgs (pkgs: import ./shell.nix {inherit pkgs;});

    formatter = forEachPkgs (pkgs: treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper);

    checks = forEachPkgs (pkgs: {
      formatting = treefmtEval.${pkgs.stdenv.hostPlatform.system}.config.build.check self;
    });

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      lilith = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          inputs.sops-nix.nixosModules.sops
          nix-defaults

          ./hosts/lilith/configuration.nix
        ];
      };
      morrigan = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          inputs.sops-nix.nixosModules.sops
          nix-defaults

          ./hosts/morrigan/configuration.nix
        ];
      };
    };

    homeConfigurations = {
      nathan = home-manager.lib.homeManagerConfiguration (
        import ./home/nathan {inherit inputs outputs nix-defaults;}
      );
    };
  };

  nixConfig = {
    # add binary caches
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
      "copier.cachix.org-1:sVkdQyyNXrgc53qXPCH9zuS91zpt5eBYcg7JQSmTBG4="
      "wezterm.cachix.org-1:kAbhjYUC9qvblTE+s7S+kl5XM1zVa4skO+E/1IDWdH0="
      "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
    ];
    substituters = [
      "https://cache.nixos.org"
      "https://devenv.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://anyrun.cachix.org"
      "https://copier.cachix.org"
      "https://wezterm.cachix.org"
      "https://nixpkgs-python.cachix.org"
    ];
  };

  inputs = {
    # Nixpkgs
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs";
    # nixpkgs-unstable.url = "github:nixos/nixpkgs/092b4f17187b623239eae0cb75ea89124c23f5f9";
    nixpkgs.follows = "nixpkgs-stable";
    # nixpkgs.follows = "nixpkgs-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-26.05";

    sops-nix.url = "github:Mic92/sops-nix";
    agenix.url = "github:yaxitech/ragenix";

    treefmt-nix.url = "github:numtide/treefmt-nix";

    nix-alien.url = "github:thiagokokada/nix-alien";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  inputs = {
    anyrun = {
      url = "github:Kirottu/anyrun";
    };

    walker.url = "github:abenz1267/walker";

    ags.url = "github:Aylur/ags";

    wezterm.url = "github:wez/wezterm?dir=nix&rev=7053748e4d899e7fc5e202d6f903b052fc78e759";

    networkmanager-dmenu = {
      url = "github:firecat53/networkmanager-dmenu";
      flake = false;
    };
  };

  # rice
  inputs = {
    stylix.url = "github:danth/stylix/release-24.11";

    nix-rice.url = "github:bertof/nix-rice";

    catppuccin.url = "github:catppuccin/nix/release-25.05";

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

    nvf.url = "github:notashelf/nvf";
    charm-nur = {
      url = "github:charmbracelet/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
