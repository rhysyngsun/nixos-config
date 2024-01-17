# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = import ../pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    devenv = inputs.devenv.packages.${final.system}.devenv;
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (finalPy: prevPy: {
        wheel-inspect = prevPy.wheel-inspect.overridePythonAttrs (oldAttrs: {
          postPatch = ''
            ${oldAttrs.postPatch}
            substituteInPlace setup.cfg \
              --replace "headerparser     ~= 0.4.0" "headerparser     >= 0.4.0,< 0.6"
          '';
        });
      })

    ];
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
