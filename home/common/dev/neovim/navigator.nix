{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      nvim-web-devicons
      overseer-nvim
      Navigator-nvim
    ];
    extraConfigLua = ''
      require('Navigator').setup()
    '';

    keymaps = [
      {
        mode = [
          "n"
          "t"
        ];
        key = "<C-h>";
        action = "<CMD>NavigatorLeft<CR>";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<C-l>";
        action = "<CMD>NavigatorRight<CR>";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<C-k>";
        action = "<CMD>NavigatorUp<CR>";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<C-j>";
        action = "<CMD>NavigatorDown<CR>";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<C-p>";
        action = "<CMD>NavigatorPrevious<CR>";
      }
    ];
  };
}
