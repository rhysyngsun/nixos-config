{ config, pkgs, ... }:
{
  home = {
    shellAliases = import ./aliases.nix;

    packages = with pkgs; [
      gita
      pre-commit
    ];
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

      # delta.enable = true;
      difftastic.enable = true;
      lfs.enable = true;

      ignores = [
        ".direnv/"
        ".envrc"
        ".devenv/"
      ];

      includes = [
        { path = "${config.xdg.configHome}/git/default.gitconfig"; }
        {
          path = "${config.xdg.configHome}/git/ol.gitconfig";
          condition = "hasconfig:remote.*.url:git@github.com:mitodl/**";
        }
      ];
    };
  };
}
