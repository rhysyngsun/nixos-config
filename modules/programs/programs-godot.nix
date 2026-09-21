{ ... }:
{
  flake.modules.homeManager.programs-godot =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        godot_4_7
        godot-voxel
      ];
    };
}
