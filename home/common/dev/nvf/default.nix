{pkgs, lib, inputs, ... }: let
  inherit (inputs.nvf.lib.nvim.binds) mkKeymap;
  inherit (lib.generators) mkLuaInline;
in {
  imports = [
    ./completion.nix
    ./folding.nix
    ./git.nix
    ./languages.nix
    ./spectre.nix
    ./undotree.nix
  ];

  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        viAlias = true;
        vimAlias = true;

        globals = {
          mapleader = ",";
        };

        lsp = {
          enable = true;
        };

        lazy.plugins = {
          "oil.nvim" = {
            package = pkgs.vimPlugins.oil-nvim;
            setupModule = "oil";
            lazy = false;
          };
        };

        telescope = {
          enable = true;
        };
        lazy.plugins.telescope.keys = [
          (mkKeymap "n" "<leader>fG" "<cmd>Telescope grep_string<CR>" {})
        ];

        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
        };

        ui = {
          colorizer.enable = true;
        };

        visuals = {
          nvim-web-devicons.enable = true;
          tiny-devicons-auto-colors = {
            enable = true;
            setupOpts = {
              colors = mkLuaInline ''
                require("catppuccin.palettes").get_palette("mocha")
              '';
            };
          };
        };

        keymaps = [
          {
            mode = "n";
            key = "<leader>pv";
            action = "<CMD>Oil<CR>";
          }
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
            mode = ["n" "v"];
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
            mode = ["n" "v"];
            key = "<leader>|";
            action = "<CMD>vsplit<CR>";
          }
          {
            mode = ["n" "v"];
            key = "<leader>-";
            action = "<CMD>split<CR>";
          }
          {
            mode = ["n" "v"];
            key = "ga."; 
            action = "<CMD>TextCaseOpenTelescope<CR>";
          }
        ];

        options = {
          number = true; # Show line numbers
          relativenumber = true; # Show relative line numbers
          tabstop = 2;
          shiftwidth = 2;
          expandtab = true;
        };
      };
    };
  };
}
