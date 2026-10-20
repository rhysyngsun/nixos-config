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
    # vimPlugins = mkVimPlugins prev prev.localSources;
  };

  # Applied to the nixpkgs-master instance only, to unbreak master-only
  # regressions that would otherwise block the whole home closure. Keep this
  # list short and delete entries as upstream catches up - it is a workaround
  # shelf, not a customization layer.
  edge-fixes = _: prev: {
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (_finalPy: prevPy: {
        # Pygments 2.21 escapes `"` as `&quot;`, so diff-cover's golden HTML
        # fixtures no longer match and six integration tests fail. That takes
        # out sqlfluff, which nvf pulls in as the default SQL formatter, which
        # takes out init.lua and therefore home-manager-path. Upstream already
        # disables two other HTML tests for the same class of reason but has
        # not caught these; drop this block once it does.
        diff-cover = prevPy.diff-cover.overridePythonAttrs (oldAttrs: {
          disabledTests = oldAttrs.disabledTests or [ ] ++ [
            "test_added_file_pycodestyle_html"
            "test_added_file_pyflakes_html"
            "test_added_file_pylint_html"
            "test_all_reports"
            "test_fail_under_html"
            "test_fail_under_pass_html"
          ];
        });
      })
    ];
  };

  # Channel-crossing tweaks applied to the nixpkgs-unstable instance. Curried on
  # the stable set because `localSources` and the pkl grammar only exist there
  # (`additions` is not applied to unstable). Consumed by
  # modules/pkgs-instances.nix; not exported through `flake.overlays`, which
  # only accepts plain two-argument overlays.
  unstable-extras = pkgs-stable: _: prev': {
    # vimPlugins = mkVimPlugins prev' pkgs-stable.localSources;
  };
}
