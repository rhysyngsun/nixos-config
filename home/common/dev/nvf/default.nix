{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
in
{
  imports = [
    ./blender.nix
    ./completion.nix
    ./folding.nix
    ./git.nix
    ./languages.nix
    ./lsp.nix
    ./oil.nix
    ./spectre.nix
    ./telescope.nix
    ./undotree.nix
  ];

  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        viAlias = true;
        vimAlias = true;

        package = pkgs.unstable.neovim-unwrapped;

        globals = {
          mapleader = ",";
        };

        autopairs.nvim-autopairs.enable = true;

        diagnostics = {
          # enable = true;
        };
        extraPackages = with pkgs; [
          # neovim autodetects wl-copy
          wl-clipboard
        ];

        lsp = {
          enable = true;
          trouble.enable = true;
        };

        # luaConfigPre =
        #   /*
        #   lua
        #   */
        #   ''
        #     vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        #       group = vim.api.nvim_create_augroup("float_diagnostic", { clear = true }),
        #       callback = function ()
        #         vim.diagnostic.open_float(nil, {focus=false})
        #       end
        #     })
        #   '';

        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
        };

        ui = {
          colorizer.enable = true;
        };

        undoFile.enable = true;

        visuals = {
          nvim-web-devicons.enable = true;
          tiny-devicons-auto-colors = {
            enable = true;
            setupOpts = {
              colors =
                mkLuaInline
                  # lua
                  ''
                    require("catppuccin.palettes").get_palette("mocha")
                  '';
            };
          };
        };

        keymaps = [
          {
            mode = "n";
            key = "<C-u>";
            action = "<C-u>zz";
          }
          {
            mode = "n";
            key = "<C-d>";
            action = "<C-d>zz";
          }
          {
            mode = "n";
            key = "<C-c>";
            action = "<CMD>close<CR>";
          }
          {
            mode = "n";
            key = "<C-k>";
            action = "<CMD>cnext<CR>zz";
          }
          {
            mode = "n";
            key = "<C-j>";
            action = "<CMD>cprev<CR>zz";
          }
          # deletes without yanking
          {
            mode = [
              "n"
              "v"
            ];
            key = "<leader>d";
            action = "\"_d";
          }
          # paste without yanking
          {
            mode = "v";
            key = "<leader>p";
            action = "\"_dP";
          }
          # splits
          {
            mode = [
              "n"
              "v"
            ];
            key = "<leader>|";
            action = "<CMD>vsplit<CR>";
          }
          {
            mode = [
              "n"
              "v"
            ];
            key = "<leader>-";
            action = "<CMD>split<CR>";
          }
        ];

        options = {
          number = true; # Show line numbers
          relativenumber = true; # Show relative line numbers
          tabstop = 2;
          shiftwidth = 2;
          expandtab = true;
          updatetime = 250;
        };
      };
    };
  };
}
