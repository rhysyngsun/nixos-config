{
  programs.nixvim = {
    plugins.fugitive.enable = true;

    keymaps = [
      {
        mode = "n";
        key = "<leader>gs";
        action = {
          __raw = "vim.cmd.Git";
        };
      }
    ];
  };
}
