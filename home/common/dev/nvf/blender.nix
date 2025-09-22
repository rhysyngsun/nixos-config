{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    lazy.plugins."nvim-blender" = {
      package = pkgs.vimUtils.buildVimPlugin {
        version = "2024-10-11";
        pname = "nvim-blender";
        src = pkgs.fetchFromGitHub {
          owner = "b0o";
          repo = "blender.nvim";
          rev = "3b0ea86bcee052d12be77d26d6cd1518a8e4b47d";
          hash = "sha256-neq2H1hOtoPsO+pDhvEiHTIUPrBCb/e6hyJ+ySWgxvs=";
        };
        doCheck = false;
      };
      setupModule = "blender";
      setupOpts = {
      };
      cmd = [
        "Blender"
        "BlenderLaunch"
        "BlenderManage"
        "BlenderReload"
        "BlenderWatch"
        "BlenderUnwatch"
        "BlenderOutput"
      ];
      keys = [
      ];
    };

    extraPlugins = with pkgs.vimPlugins; {
      nui = {
        package = nui-nvim;
      };
      nui-components = {
        package = pkgs.vimUtils.buildVimPlugin {
          version = "2025-03-15";
          pname = "nui-components";
          src = pkgs.fetchFromGitHub {
            owner = "grapp-dev";
            repo = "nui-components.nvim";
            rev = "1654dd709f13874089eefc80d82e0eb667f7fdfb";
            hash = "sha256-dq/HZ2EEbGu4uHEJQ4tJPSgIn72wga6Bf3ku3XvjKkY=";
          };
          doCheck = false;
        };
      };
    };
  };
}
