{pkgs, ...}:
{
  programs.nvf.vim.lazy.plugins.undotree = {
    package = pkgs.vimPlugins.undotree;
    setupModule = "undotree";

    keymaps = [
      {
        mode = ["n" "v"];
        key = "<leader>u";
        action = "<cmd>vim.cmd.UndotreeToggle<CR>";
      }
    ];
  };
}
