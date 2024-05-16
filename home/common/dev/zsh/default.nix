{ config, pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      starship
    ];
    file.".profile".text = ''
      case $- in
        *i* )
          if command -v zsh > /dev/null; then
              zsh --version > /dev/null && exec zsh
              echo "Couldn't run 'zsh'" > /dev/stderr
          fi
          ;;
      esac
    '';
  };

  xdg.configFile = {
    "starship.toml".source = ../../../../config/starship.toml;
  };

  programs = {
    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        filter_mode = "session";
      };
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable= true;
      history = {
        extended = true;
      };

      initExtra = ''
        eval "$(${pkgs.starship}/bin/starship init zsh)"
        eval "$(${config.programs.zoxide.package}/bin/zoxide init zsh)"
      '';

      plugins = [
        {
          name = "zsh-autosuggestions";
          src = pkgs.fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-autosuggestions";
            rev = "v0.7.0";
            hash = "sha256-KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
          };
        }
        {
          name = "zsh-syntax-highlighting";
          src = pkgs.fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-syntax-highlighting";
            rev = "754cefe0181a7acd42fdcb357a67d0217291ac47";
            hash = "sha256-kWgPe7QJljERzcv4bYbHteNJIxCehaTu4xU9r64gUM4=";
          };
        }
      ];
    };
  };
}
