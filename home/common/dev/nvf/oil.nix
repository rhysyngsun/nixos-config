{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
in
{
  programs.nvf.settings.vim = {
    lazy.plugins = {
      "oil.nvim" = {
        package = pkgs.unstable.vimPlugins.oil-nvim;
        setupModule = "oil";
        lazy = false;
        setupOpts = {
          keymaps = {
            "gd" = {
              desc = "Toggle file detail view";
              callback =
                mkLuaInline
                  # lua
                  ''
                    function ()
                      detail = not detail
                      if detail then
                        require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
                      else
                        require("oil").set_columns({ "icon" })
                      end
                    end
                  '';
            };
          };
        };
      };
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>fd";
        action = "<CMD>:Oil<CR>";
      }
    ];
  };
}
