{ ... }:
{
  flake.modules.homeManager.programs-godot =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        pkgs-edge.godot_4_7
        godot-voxel
      ];
    };
}
