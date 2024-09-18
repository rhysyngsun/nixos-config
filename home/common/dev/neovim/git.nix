{
  programs.nixvim = {
    plugins = {
      lazygit = {
        enable = true;
        settings = {
          floating_window_scaling_factor = 0.99;
          floating_window_use_plenary = 1;
        };
      };
      octo.enable = true;
    };
    keymaps = [
      {
        key = "<leader>gz";
        action = ":LazyGit<cr>";
        mode = "n";
        options.silent = true;
        options.desc = "Lazygit";
      }
    ];
  };
}
