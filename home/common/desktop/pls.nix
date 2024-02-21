{ config, lib, ... }:

with lib;

let
  cfg = config.programs.pls;
  aliases = {
    ll =
      mkForce "${cfg.package}/bin/pls -d perm -d user -d group -d size -d mtime -d git";
  };
in
{
  programs.pls.enable = true;

  # don't use enableAliases because we don't want to alias `ls`
  programs.bash.shellAliases = aliases;
  programs.fish.shellAliases = aliases;
  programs.zsh.shellAliases = aliases;
}

