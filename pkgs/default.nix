final: prev: let
  sources = prev.callPackage ./_sources/generated.nix {};
in
{
  catppuccin-themes = {
    btop = sources.catppuccin-btop;
    godot = sources.catppuccin-godot;
    rofi = sources.catppuccin-rofi;
  };
  catppuccin-palette = prev.callPackage ./catppuccin-palette.nix {};
  rice = prev.callPackage ./rice.nix {};
  mit = prev.callPackage ./mit {};
  krita-plugins = prev.callPackage ./krita-plugins {};
  easyeffects-presets = prev.callPackage ./easyeffects-presets {};
  hyprshot = prev.callPackage ./hyprshot.nix {};
  godot-voxel = prev.callPackage ./godot-voxel.nix {};
  headlamp = prev.callPackage ./headlamp.nix { source = sources.headlamp; };
}
