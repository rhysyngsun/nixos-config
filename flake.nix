{
  description = "Rhysyngsun's nixos configs";

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      {
        self,
        inputs,
        config,
        lib,
        ...
      }:
      let
        inherit (inputs.nixpkgs.lib.fileset) toList fileFilter;
        import-tree =
          path: toList (fileFilter (file: file.hasExt "nix" && !(lib.hasPrefix "_" file.name)) path);

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

        system = "x86_64-linux";
        hostModules = lib.filterAttrs (n: _: lib.hasPrefix "host-" n) config.flake.modules.nixos;
        homeModules = lib.filterAttrs (n: _: lib.hasPrefix "home-" n) config.flake.modules.homeManager;
      in
      {
        systems = [ system ];

        imports = [
          # Declares `flake.modules.<class>.<name>` as a real, mergeable option so every
          # self-registering file under ./modules can independently contribute an entry
          # without colliding (flake-parts' own `flake.*` freeform doesn't deep-merge this).
          (
            { lib, ... }:
            {
              options.flake.modules = lib.mkOption {
                type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
                default = { };
              };
            }
          )
        ]
        ++ import-tree ./modules;

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

          nixosConfigurations = lib.mapAttrs' (
            name: mod:
            lib.nameValuePair (lib.removePrefix "host-" name) (
              inputs.nixpkgs.lib.nixosSystem {
                inherit system;
                specialArgs = { inherit inputs; };
                modules = [
                  inputs.sops-nix.nixosModules.sops
                  nix-defaults
                  mod
                ];
              }
            )
          ) hostModules;

          homeConfigurations = lib.mapAttrs' (
            name: mod:
            lib.nameValuePair (lib.removePrefix "home-" name) (
              inputs.home-manager.lib.homeManagerConfiguration {
                pkgs = import inputs.nixpkgs {
                  inherit system;
                  inherit (nix-defaults.nixpkgs) config overlays;
                };
                extraSpecialArgs = { inherit system inputs; };
                modules = [
                  mod
                  (
                    { pkgs, ... }:
                    {
                      nix = {
                        package = pkgs.nix;
                        inherit (nix-defaults.nix) settings;
                      };
                    }
                  )
                ];
              }
            )
          ) homeModules;
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
    nixpkgs.follows = "nixpkgs-stable";
    # nixpkgs.follows = "nixpkgs-master";

    # Home manager
    # home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.url = "github:nix-community/home-manager";

    sops-nix.url = "github:Mic92/sops-nix";
    agenix.url = "github:yaxitech/ragenix";

    # Python packaging — used by pkgs/mit/witan.nix to build the witan MCP
    # server hermetically from agent-kit's own uv.lock.
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    nvf.url = "github:notashelf/nvf?tag=v26.07";
  };
}
