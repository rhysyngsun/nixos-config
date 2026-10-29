{ ... }:
{
  flake.modules.homeManager.programs-ai-unsloth =
    { pkgs-unstable, ... }:
    {
      home.packages = [ pkgs-unstable.unsloth-desktop ];
    };
}
