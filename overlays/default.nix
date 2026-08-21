# This file defines overlays
{ inputs, ... }:
let
  mkVimPlugins =
    prev: localSources:
    prev.vimPlugins.extend (
      _: prev': {
        nvim-treesitter = prev'.nvim-treesitter.overrideAttrs (
          _: _: {
          }
        );
      }
    );
in
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = import ../pkgs { inherit inputs; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    devenv = inputs.devenv.packages.${final.stdenv.hostPlatform.system}.devenv;
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (_finalPy: prevPy: {
        wheel-inspect = prevPy.wheel-inspect.overridePythonAttrs (oldAttrs: {
          postPatch = ''
            ${oldAttrs.postPatch}
            substituteInPlace setup.cfg \
              --replace "headerparser     ~= 0.4.0" "headerparser     >= 0.4.0,< 0.6"
          '';
        });
      })
    ];
    vimPlugins = mkVimPlugins prev prev.localSources;
  };

  # Channel-crossing tweaks applied to the nixpkgs-unstable instance. Curried on
  # the stable set because `localSources` and the pkl grammar only exist there
  # (`additions` is not applied to unstable). Consumed by
  # modules/pkgs-instances.nix; not exported through `flake.overlays`, which
  # only accepts plain two-argument overlays.
  unstable-extras = pkgs-stable: _: prev': {
    vimPlugins = mkVimPlugins prev' pkgs-stable.localSources;
    tree-sitter = pkgs-stable.tree-sitter.override {
      extraGrammars = {
        tree-sitter-pkl = pkgs-stable.tree-sitter.buildGrammar {
          language = "pkl";
          inherit (pkgs-stable.localSources.tree-sitter-pkl) src version;
        };
      };
    };
  };
}
