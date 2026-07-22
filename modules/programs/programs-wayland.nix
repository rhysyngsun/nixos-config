# The actual multi-file module tree lives at ../../home/wayland (outside modules/), since
# its files are plain home-manager modules, not flake-parts modules -- import-tree would
# otherwise try to import each of them directly as a flake-parts module.
{ ... }:
{
  flake.modules.homeManager.programs-wayland = {
    imports = [ ../../home/wayland ];
  };
}
