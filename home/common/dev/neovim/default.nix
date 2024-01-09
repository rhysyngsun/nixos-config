{ pkgs, ... }: 
{
  imports = [
    ./colorschemes.nix
    ./completion.nix
    ./fugitive.nix
    ./harpoon.nix
    ./lsp.nix
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
      number = true;         # Show line numbers
      relativenumber = true; # Show relative line numbers
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
    };

    plugins = {
      nvim-autopairs.enable = true;
      tmux-navigator.enable = true;
    };

    extraPlugins = with pkgs.vimPlugins; [
      overseer-nvim
    ];

    extraConfigLua = ''
      require('overseer').setup()
    '';
  };
}
