
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
  rice = prev.callPackage ./rice.nix {};
  blender-launcher = prev.callPackage ./blender-launcher {};
  mit = prev.callPackage ./mit {};
}
