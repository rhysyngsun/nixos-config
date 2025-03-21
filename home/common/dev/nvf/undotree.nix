{pkgs, ...}:
{
  programs.nvf.settings.vim = {
    lazy.plugins.undotree = {
      package = pkgs.vimPlugins.undotree;
      before = ''
        vim.g.undotree_SetFocusWhenToggle = 1
        vim.g.undotree_ShortIndicators = true
        
	vim.g.undotree_TreeNodeShape = '├'
	vim.g.undotree_TreeVertShape = '│'
	vim.g.undotree_TreeSplitShape = '─┘'
	vim.g.undotree_TreeReturnShape = '─┐'
        vim.g.undotree_TreeNodeShape = ""
      '';
      cmd = ["UndotreeFocus" "UndotreeHide" "UndotreePersistUndo" "UndotreeShow" "UndotreeToggle"];
      keys = [
        {
          mode = ["n" "v"];
          key = "<leader>u";
          action = "<cmd>:UndotreeToggle<cr>";
        }
      ];
    };

  };
}
