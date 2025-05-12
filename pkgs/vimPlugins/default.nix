{pkgs, sources, ...}:
{
  pkl-neovim = pkgs.callPackage ./pkl-neovim.nix { source = sources.pkl-neovim; };
}
