{ pkgs, ... }:
{
  config.vim = {
    lazy.plugins."nvim-blender" = {
      package = pkgs.vimUtils.buildVimPlugin {
        version = "2025-10-17";
        pname = "nvim-blender";
        src = pkgs.fetchFromGitHub {
          owner = "b0o";
          repo = "blender.nvim";
          rev = "f200feac023ba4ab04f7b8dd28505ea9b06ec518";
          hash = "sha256-G6XKVi4RhACRLEZLwz+0CjYhVb+9clhfD18juEhhtUo=";
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
