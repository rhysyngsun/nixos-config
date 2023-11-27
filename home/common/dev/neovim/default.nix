{pkgs, inputs, ...}:
{
  imports = [
    ./colorschemes.nix
    ./fugitive.nix
    ./harpoon.nix
    ./lsp.nix
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
        action = "vim.cmd.Ex";
      }
    ];

    globals.mapleader = "<Space>";

    options = {
      number = true;         # Show line numbers
      relativenumber = true; # Show relative line numbers
    };
  };
}