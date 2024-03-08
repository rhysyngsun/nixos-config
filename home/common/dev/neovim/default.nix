{ pkgs, ... }:
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
    ./project-nvim.nix
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
        key = "<C-k>";
        action = "<cmd>cnext<CR>zz";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<cmd>cprev<CR>zz";
      }
    ];

    globals.mapleader = ",";

    options = {
      number = true; # Show line numbers
      relativenumber = true; # Show relative line numbers
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
    };

    plugins = {
      comment-nvim.enable = true;
      lualine.enable = true;
      nvim-autopairs.enable = true;
      trouble.enable = true;
    };

    extraPlugins = with pkgs.vimPlugins; [
      nvim-web-devicons
      overseer-nvim
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
