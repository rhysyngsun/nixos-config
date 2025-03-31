{pkgs, ...}:
{
  programs.nvf.settings.vim = {
    extraPackages = [pkgs.lazygit];
    git = {
      vim-fugitive.enable = true;
    };
    lazy.plugins."lazygit.nvim" = {
      package = pkgs.vimPlugins.lazygit-nvim;
      before = ''
        vim.g.floating_window_scaling_factor = 0.99
        vim.g.floating_window_use_plenary = 1
      '';
      # lazy = true;
      cmd = [
        "LazyGit"
        "LazyGitConfig"
        "LazyGitCurrentFile"
        "LazyGitFilter"
        "LazyGitFilterCurrentFile"
      ];
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
