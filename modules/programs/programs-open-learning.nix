{ ... }:
{
  flake.modules.homeManager.programs-open-learning = {
    programs.himalaya = {
      enable = true;
    };
  };
}
