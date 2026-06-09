{ pkgs, inputs, ... }:
{
  imports = [
    ./accounts
    ./desktop
    ./dev
    ./media
    ./open-learning
    ./themes
  ];

  news.display = "silent";

  home.packages = with inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}; [
    nix-alien
  ];

  sops = {
    age.keyFile = "/home/nathan/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    secrets."llms/anthropic/api_key" = {};
    secrets."llms/openrouter/api_key" = {};
  };

  xdg.userDirs.setSessionVariables = false;
}
