{
  description = "Rhysyngsun's nixos configs";

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { self, inputs, ... }:
      let
        overlays = import ./overlays { inherit inputs; };
        nix-defaults = {
          nix = import ./nix-settings.nix {
            inherit inputs;
            inherit (inputs.nixpkgs) lib;
          };
          nixpkgs = {
            overlays = [
              inputs.nix-rice.overlays.default
              inputs.nur.overlays.default
              overlays.additions
              overlays.modifications
              overlays.unstable-packages
            ];
            config.allowUnfree = true;
          };
        };
      in
      {
        systems = [ "x86_64-linux" ];

        perSystem =
          { pkgs, ... }:
          let
            treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
          in
          {
            devShells = import ./shell.nix { inherit pkgs; };
            formatter = treefmtEval.config.build.wrapper;
            checks.formatting = treefmtEval.config.build.check self;
          };

        flake = {
          inherit overlays;

          nixosModules.default = import ./modules/nixos;
          homeManagerModules.default = import ./modules/home-manager;

          nixosConfigurations = {
            lilith = inputs.nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = { inherit inputs; };
              modules = [
                inputs.sops-nix.nixosModules.sops
                nix-defaults
                ./hosts/lilith/configuration.nix
              ];
            };
            morrigan = inputs.nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = { inherit inputs; };
              modules = [
                inputs.sops-nix.nixosModules.sops
                nix-defaults
                ./hosts/morrigan/configuration.nix
              ];
            };
          };

          homeConfigurations = {
            nathan = inputs.home-manager.lib.homeManagerConfiguration (
              import ./home/nathan {
                inherit inputs nix-defaults;
                outputs = self;
              }
            );
          };
        };
      }
    );

  nixConfig = {
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
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Nixpkgs
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs";
    nixpkgs.follows = "nixpkgs-unstable";
    # nixpkgs.follows = "nixpkgs-unstable";

    # Home manager
    # home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.url = "github:nix-community/home-manager";

    sops-nix.url = "github:Mic92/sops-nix";
    agenix.url = "github:yaxitech/ragenix";

    treefmt-nix.url = "github:numtide/treefmt-nix";

    nix-alien.url = "github:thiagokokada/nix-alien";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anyrun.url = "github:Kirottu/anyrun";
    walker.url = "github:abenz1267/walker";
    ags.url = "github:Aylur/ags";
    wezterm.url = "github:wez/wezterm?dir=nix&rev=7053748e4d899e7fc5e202d6f903b052fc78e759";

    networkmanager-dmenu = {
      url = "github:firecat53/networkmanager-dmenu";
      flake = false;
    };

    # rice
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
  };
}
