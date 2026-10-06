{ ... }: {
  flake.modules.homeManager.programs-godot =
    { pkgs, ... }:
    {
      # Note: Using nixpkgs godot_4_7 (standard) + local godot-48-beta package
      home.packages = with pkgs; [
        godot_4_7
        godot-48-beta
      ];
    };
}
