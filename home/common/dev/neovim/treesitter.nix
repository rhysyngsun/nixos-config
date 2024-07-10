{
  programs.nixvim.plugins = {
    treesitter = {
      enable = true;
      folding = true;
      nixvimInjections = true;
      settings.indent.enable = true;
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
