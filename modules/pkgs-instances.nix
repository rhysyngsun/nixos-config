# The single nixpkgs instantiation site for the whole flake.
#
# flake.parts "Approach 2" (https://flake.parts/system.html): every configured
# package set is built once here, in perSystem, and reached from the top level
# with `withSystem`. flake.nix hands `pkgs` to nixosSystem through
# `nixpkgs.nixosModules.readOnlyPkgs` and to homeManagerConfiguration directly,
# so the system and both home closures share one evaluation instead of each
# building its own.
#
# `pkgs-unstable` and `pkgs-edge` are plain module arguments, not attributes
# bolted onto the stable set by an overlay. Reach them by naming them in a
# module's argument list - there is no `pkgs.pkgs-unstable` any more.
{ inputs, ... }:
let
  overlays = import ../overlays { inherit inputs; };
in
{
  # `unstable-extras` is deliberately absent: it is curried on the stable set,
  # and flake.overlays only accepts plain two-argument overlays.
  flake.overlays = { inherit (overlays) additions modifications; };

  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.nix-rice.overlays.default
          inputs.nur.overlays.default
          overlays.additions
          overlays.modifications
        ];
      };
    in
    {
      _module.args = {
        inherit pkgs;

        pkgs-unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
          # Fed the stable set on purpose: `localSources` and the custom
          # vimPlugins come from `additions`, which is stable-only.
          overlays = [ (overlays.unstable-extras pkgs) ];
        };

        # Intentionally unoverlaid. nvf/ evaluates against this and reaches
        # back into stable via the `pkgs-stable` arg for anything from
        # `additions` - see modules/programs/programs-neovim.nix.
        pkgs-edge = import inputs.nixpkgs-master {
          inherit system;
          config.allowUnfree = true;
        };
      };
    };
}
