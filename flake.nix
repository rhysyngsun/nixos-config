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
          # hyprland
          inputs.hyprcursor.overlays.default
          inputs.nur.overlays.default
          # from flake outputs
          outputs.overlays.additions
          outputs.overlays.modifications
          outputs.overlays.unstable-packages
        ];
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "electron-25.9.0"
            "python3.12-youtube-dl-2021.12.17"
          ];
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

    formatter = forEachPkgs (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);

    checks = forEachPkgs (pkgs: {
      formatting = treefmtEval.${pkgs.system}.config.build.check self;
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
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
      "copier.cachix.org-1:sVkdQyyNXrgc53qXPCH9zuS91zpt5eBYcg7JQSmTBG4="
      "wezterm.cachix.org-1:kAbhjYUC9qvblTE+s7S+kl5XM1zVa4skO+E/1IDWdH0="
      "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
    ];
    substituters = [
      "https://cache.nixos.org"
      "https://devenv.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://hyprland.cachix.org"
      "https://anyrun.cachix.org"
      "https://copier.cachix.org"
      "https://wezterm.cachix.org"
      "https://nixpkgs-python.cachix.org"
    ];
  };

  inputs = {
    # Nixpkgs
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nixpkgs-stable";
    # nixpkgs.follows = "nixpkgs-unstable";

    pinned-textual-nixpkgs.url = "github:nixos/nixpkgs/9b008d60392981ad674e04016d25619281550a9d";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-25.05";

    sops-nix.url = "github:Mic92/sops-nix";

    treefmt-nix.url = "github:numtide/treefmt-nix";

    nix-alien.url = "github:thiagokokada/nix-alien";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  inputs = {
    # hyprland = {
    #   url = "github:hyprwm/Hyprland?ref=v0.40.0";
    # };
    hyprland = {
      url = "git+https://github.com/hyprwm/hyprland?submodules=1";
      # url = "git+ssh://git@github.com/hyprwm/Hyprland?submodules=1";
      # inputs.nixpkgs.follows="nixpkgs-unstable";
    };

    # hy3 = {
    #   url = "github:outfoxxed/hy3";
    #   # or "github:outfoxxed/hy3" to follow the development branch.
    #   # (you may encounter issues if you dont do the same for hyprland)
    #   inputs.hyprland.follows = "hyprland";
    # };

    # hyprspace = {
    #   url = "github:KZDKM/Hyprspace";
    #   inputs.hyprland.follows = "hyprland";
    # };

    hyprpicker.url = "github:hyprwm/hyprpicker";
    hyprcursor.url = "github:hyprwm/hyprcursor";
  };

  inputs = {
    anyrun = {
      url = "github:Kirottu/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    nvf.url = "github:notashelf/nvf?rev=ab991a7e57de67ae8e14b2d6a3ad27368ab1d5e3";
  };
}
