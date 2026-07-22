{ ... }:
{
  flake.modules.homeManager.programs-vscode = {
    programs.vscode = {
      enable = true;
      mutableExtensionsDir = true;
    };
  };
}
