{
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;
      folding = true;
      indent = true;
      nixvimInjections = true;
    };
    treesitter-context = {
      enable= true;
    };
    treesitter-refactor = {
      enable = true;
    };
    treesitter-textobjects = {
      enable = true;
    };
  };
}
