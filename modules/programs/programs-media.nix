{ ... }:
{
  flake.modules.homeManager.programs-media =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        spotify
        twitch-dl
      ];
    };
}
