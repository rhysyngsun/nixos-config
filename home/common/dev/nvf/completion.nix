{
  programs.nvf.settings.vim.autocomplete.nvim-cmp = {
    enable = true;
    setupOpts = {
      completion = {
        autocomplete = [ "TextChanged" ];
        keywordLength = 1;
      };
    };
    sources = {
      "buffer" = "[Buffer]";
      "path" = "[Path]";
      "nvim_lsp" = "[LSP]";
      "nvim-cmp" = null;
    };
  };
}
