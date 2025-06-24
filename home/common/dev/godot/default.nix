{pkgs, ...}: {
  home.packages = with pkgs; [unstable.godot godot-voxel];
}
