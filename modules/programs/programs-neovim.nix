# The actual nvf module tree lives at ../../nvf (outside modules/), since it uses
# nvf's own `vim.*` option schema, not the flake-parts module schema import-tree expects.
{ ... }:
{
  flake.modules.homeManager.programs-neovim =
    { inputs, pkgs, ... }:
    {
      home.packages = [
        (inputs.nvf.lib.neovimConfiguration {
          pkgs = pkgs.pkgs-edge;
          modules = [
            {
              _module.args = {
                pkgs-stable = pkgs;
              };
            }
            ../../nvf
          ];
        }).neovim
      ];
    };
}
