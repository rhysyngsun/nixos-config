{ lib, ... }:
let
  inherit (lib.nvim.binds) mkKeymap;
in
{
  config.vim = {
    telescope = {
      enable = true;
      setupOpts = {
        defaults.layout_config = {
          width = 0.95;
          height = 0.95;
        };
      };
    };

    lazy.plugins.telescope.keys = [
      (mkKeymap "n" "<leader>fG" "<cmd>:Telescope grep_string<CR>" { })
    ];

    autocmds = [
    ];
  };
}
