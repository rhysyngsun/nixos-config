{ config, pkgs, ... }:
{
  home = {
    shellAliases = import ./aliases.nix;

    packages = with pkgs; [pre-commit ];
  };

  xdg.configFile."git" = {
    source = ../../../../config/git;
    recursive = true;
  };

  programs = {
    gh = {
      # github CLI
      enable = true;
      # gitCredentialHelper.enable = true;
      settings = {
        git_protocol = "ssh";
      };
    };

    git = {
      enable = true;

      delta = {
        enable = true;
      };

      ignores = [
        ".direnv/"
        ".envrc"
      ];

      lfs.enable = true;

      includes = [
        { path = "${config.xdg.configHome}/git/default.gitconfig"; }
        {
          path = "${config.xdg.configHome}/git/ol.gitconfig";
          condition = "hasconfig:remote.*.url:https://github.com/mitodl/**";
        }
      ];
    };
  };
}
