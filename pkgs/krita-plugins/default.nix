{ callPackage }: {
  buli-brush-switch = callPackage ./buli-brush-switch.nix { };
  compact-brush-toggler = callPackage ./compact-brush-toggler.nix { };
  shapes-and-layers = callPackage ./shapes-and-layers.nix { };
  shortcut-composer = callPackage ./shortcut-composer.nix { };
  subwindow-organizer = callPackage ./subwindow-organizer.nix { };
  ui-redesign = callPackage ./ui-redesign.nix { };
}
