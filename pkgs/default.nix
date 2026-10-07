{ inputs }:
_final: prev:
let
  sources = prev.callPackage ./_sources/generated.nix { };
in
{
  rice = prev.callPackage ./rice.nix { };
  mit = prev.callPackage ./mit { inherit sources inputs; };
  krita-plugins = prev.callPackage ./krita-plugins { };
  easyeffects-presets = prev.callPackage ./easyeffects-presets { };
  dagger = prev.callPackage ./dagger.nix { source = sources.dagger; };
  godot-48-beta = prev.callPackage ./godot-48-beta.nix { source = sources.godot-48-beta; };
  godot-voxel = prev.callPackage ./godot-voxel.nix { source = sources.godot-voxel; };
  headlamp = prev.callPackage ./headlamp.nix { source = sources.headlamp; };
  lean-ctx = prev.callPackage ./lean-ctx.nix { source = sources.lean-ctx; };
  omnigraph = prev.callPackage ./omnigraph.nix { source = sources.omnigraph; };
  pkl-lsp = prev.callPackage ./pkl-lsp.nix { source = sources.pkl-lsp; };
  tree-sitter-peg = prev.callPackage ./tree-sitter-peg.nix { source = sources.tree-sitter-peg; };
  tree-sitter-noy = prev.callPackage ./tree-sitter-noy.nix { source = sources.tree-sitter-noy; };
  unsloth-studio = prev.callPackage ./unsloth-studio.nix { source = sources.unsloth-studio; };
  vimPlugins = prev.vimPlugins // prev.callPackage ./vimPlugins { inherit sources; };
  localSources = sources;
}
