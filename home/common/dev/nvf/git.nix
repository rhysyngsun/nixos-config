{pkgs, ...}:
{
  programs.nvf.settings.vim = {
    git = {
      vim-fugitive.enable = true;
    };
    lazy.plugins."lazygit.nvim" = {
      package = pkgs.vimPlugins.lazygit-nvim;
      before = ''
        vim.g.floating_window_scaling_factor = 0.99
        vim.g.floating_window_use_plenary = 1
      '';
      keys = [
        {
          key = "<leader>gz";
          action = ":LazyGit<cr>";
          mode = "n";
        }
      ];
    };
  };
}
