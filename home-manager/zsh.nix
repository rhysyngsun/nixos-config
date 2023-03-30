{ pkgs, config, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
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
}
