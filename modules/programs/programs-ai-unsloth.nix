{ ... }:
{
  flake.modules.homeManager.programs-ai-unsloth =
    { pkgs, pkgs-unstable, ... }:
    {
      home.packages = [
        pkgs-unstable.unsloth-desktop
        pkgs.ollama-cuda
      ];
    };
}
