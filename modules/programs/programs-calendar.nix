{ ... }:
{
  flake.modules.homeManager.programs-calendar = {
    programs.khal = {
      enable = true;
    };
  };
}
