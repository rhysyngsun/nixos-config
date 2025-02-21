{
  programs.nvf.vim.autocomplete.nvim-cmp = {
    enable = true;
    setupOpts = {
      completion = {
        autocomplete = [ "TextChanged" ];
        keywordLength = 1;
      };
    };
    sources = [
      { name = "nvim_lsp"; }
      { name = "nvim_lua"; }
      { name = "vsnip"; }
      { name = "path"; }
      { name = "buffer"; }
    ];
  };
}
