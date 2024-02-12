
final: prev:
{
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (finalPy: prevPy: {
      tutor = finalPy.callPackage ./python/tutor.nix {};
      tutor-discovery = finalPy.callPackage ./python/tutor-discovery.nix {};
      tutor-license = finalPy.callPackage ./python/tutor-license.nix {};
      tutor-mfe = finalPy.callPackage ./python/tutor-mfe.nix {};
    })
  ];
  catppuccin-palette = prev.callPackage ./catppuccin-palette.nix {};
  rice = prev.callPackage ./rice.nix {};
  blender-launcher = prev.callPackage ./blender-launcher {};
  blender-alpha = prev.callPackage ./blender-alpha {};
  mit = prev.callPackage ./mit {};
  # pants = prev.callPackage ./tools/pants {};
  krita-plugins = prev.callPackage ./krita-plugins {};
  easyeffects-presets = prev.callPackage ./easyeffects-presets {};
}
