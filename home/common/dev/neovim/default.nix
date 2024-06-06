{ pkgs, config, ... }:
{
  imports = [
    ./colorschemes.nix
    ./completion.nix
    ./folding.nix
    ./fugitive.nix
    ./harpoon.nix
    ./lsp.nix
    ./navigator.nix
    ./oil.nix
#    ./project-nvim.nix
    ./telescope.nix
    ./treesitter.nix
    ./undotree.nix
  ];

  programs.nixvim = {
    enable = true;

    viAlias = true;
    vimAlias = true;

    clipboard.providers.wl-copy.enable = true;

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
      {
        mode = "n";
        key = "gd";
        action = "vim.lsp.buf.hover";
        lua = true;
      }
      {
        mode = "n";
        key = "gD";
        action = "vim.lsp.buf.declaration";
        lua = true;
      }
      {
        mode = "n";
        key = "gi";
        action = "vim.lsp.buf.implementation";
        lua = true;
      }
      # deletes without yanking
      {
        mode = "n";
        key = "<leader>d";
        action = "\"_d";
      }
      {
        mode = "v";
        key = "<leader>d";
        action = "\"_d";
      }
      # paste without yanking
      {
        mode = "v";
        key = "<leader>p";
        action = "\"_dP";
      }
    ];

    globals.mapleader = ",";

    opts = {
      number = true; # Show line numbers
      relativenumber = true; # Show relative line numbers
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
    };

    plugins = {
      comment.enable = true;
      lualine.enable = true;
      neoscroll.enable = true;
      nvim-autopairs.enable = true;
      nvim-jdtls = {
        enable = true;
        data = "${config.xdg.cacheHome}/jdtls/workspace";
      };
      trouble.enable = true;
    };

    extraPlugins = with pkgs.vimPlugins; [
      nvim-web-devicons
      overseer-nvim
      (pkgs.vimUtils.buildVimPlugin {
        name = "mjml";
        src = pkgs.fetchFromGitHub {
          owner = "amadeus";
          repo = "vim-mjml";
          rev = "cb6249b1b49994ecaebd67a7fb421dce923bcd02";
          hash = "sha256-iQkjHY/mD++ac3o+6fw6YxCaXJEVexVjcBWsnKCfYdM=";
        };
      })
    ];

    extraConfigLua = ''
      vim.opt.termguicolors = true

      require('overseer').setup()

      require('lualine').setup({
        options = {
          component_separators = '|',
          section_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = {
            { 'mode', separator = { left = '' }, right_padding = 2 },
          },
          lualine_b = { 'filename', 'branch' },
          lualine_c = { 'fileformat' },
          lualine_x = {},
          lualine_y = { 'filetype', 'progress' },
          lualine_z = {
            { 'location', separator = { right = '' }, left_padding = 2 },
          },
        },
        inactive_sections = {
          lualine_a = { 'filename' },
          lualine_b = {},
          lualine_c = {},
          lualine_x = {},
          lualine_y = {},
          lualine_z = { 'location' },
        },
      })
    '';
  };
}
