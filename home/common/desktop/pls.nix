{ config, lib, ... }:

with lib;

let
  cfg = config.programs.pls;
  aliases = {
    ll =
      mkForce "${cfg.package}/bin/pls -d perm -d user -d group -d size -d mtime -d git";
  };
in {
  programs.pls = {
    enable = true;
    enableAliases = true;
  };

  programs.bash.shellAliases = mkIf cfg.enableAliases aliases;
  programs.fish.shellAliases = mkIf cfg.enableAliases aliases;
  programs.zsh.shellAliases = mkIf cfg.enableAliases aliases;
}

