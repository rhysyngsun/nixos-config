final: prev: {
  catppuccin-palette = prev.callPackage ./catppuccin-palette.nix {};
  rice = prev.callPackage ./rice.nix {};
  mit = prev.callPackage ./mit {};
  krita-plugins = prev.callPackage ./krita-plugins {};
  easyeffects-presets = prev.callPackage ./easyeffects-presets {};
  hyprshot = prev.callPackage ./hyprshot.nix {};
  godot-voxel = prev.callPackage ./godot-voxel.nix {};
  headlamp = prev.callPackage ./headlamp.nix {};
}
