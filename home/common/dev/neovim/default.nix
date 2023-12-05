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
        lua = true;
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
    };
  };
}
