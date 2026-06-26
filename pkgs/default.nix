final: prev: let
  sources = prev.callPackage ./_sources/generated.nix {};
in
{
  rice = prev.callPackage ./rice.nix {};
  mit = prev.callPackage ./mit { inherit sources; };
  krita-plugins = prev.callPackage ./krita-plugins {};
  easyeffects-presets = prev.callPackage ./easyeffects-presets {};
  godot-voxel = prev.callPackage ./godot-voxel.nix {};
  headlamp = prev.callPackage ./headlamp.nix { source = sources.headlamp; };
  pkl-lsp = prev.callPackage ./pkl-lsp.nix { source = sources.pkl-lsp; };
  vimPlugins = prev.vimPlugins // prev.callPackage ./vimPlugins { inherit sources; };
  localSources = sources;
}
