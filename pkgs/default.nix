{ inputs }:
final: prev:
let
  sources = prev.callPackage ./_sources/generated.nix { };
in
{
  rice = prev.callPackage ./rice.nix { };
  mit = prev.callPackage ./mit { inherit sources inputs; };
  krita-plugins = prev.callPackage ./krita-plugins { };
  easyeffects-presets = prev.callPackage ./easyeffects-presets { };
  godot-voxel = prev.callPackage ./godot-voxel.nix { };
  headlamp = prev.callPackage ./headlamp.nix { source = sources.headlamp; };
  lean-ctx = prev.callPackage ./lean-ctx.nix { source = sources.lean-ctx; };
  omnigraph = prev.callPackage ./omnigraph.nix { source = sources.omnigraph; };
  pkl-lsp = prev.callPackage ./pkl-lsp.nix { source = sources.pkl-lsp; };
  vimPlugins = prev.vimPlugins // prev.callPackage ./vimPlugins { inherit sources; };
  localSources = sources;
}
