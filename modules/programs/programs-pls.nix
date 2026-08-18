{ ... }:
{
  flake.modules.homeManager.programs-pls =
    { pkgs, lib, ... }:
    with lib;
    {
      home.packages = [ pkgs.pls ];
      # don't use enableAliases because we don't want to alias `ls`
      programs.zsh.shellAliases = {
        ll = mkForce "pls -d perm -d user -d group -d size -d mtime -d git";
      };
    };
}
