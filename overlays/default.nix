# This file defines overlays
{ inputs, ... }:
let
  mkVimPlugins = prev: localSources: prev.vimPlugins.extend(_: prev': {
    nvim-treesitter = prev'.nvim-treesitter.overrideAttrs (_: _: {
    });
  });
in
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = import ../pkgs;

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

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: prev: {
    nixos-master = import inputs.nixpkgs-master {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
      overlays = [
        (_: prev': {
          vimPlugins = mkVimPlugins prev' prev.localSources;
          tree-sitter = prev.tree-sitter.override {
            extraGrammars = {
              tree-sitter-pkl = prev.tree-sitter.buildGrammar {
                language = "pkl";
                inherit (prev.localSources.tree-sitter-pkl) src version;
              };
            };
          };
        })
      ];
    };
  };
}
