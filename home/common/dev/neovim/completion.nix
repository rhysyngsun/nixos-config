{
  programs.nixvim.plugins.nvim-cmp = {
    enable = true;
    completion = {
      autocomplete = ["TextChanged"];
      keywordLength = 1;
    };
    sources = [
      {name = "nvim_lsp";}
      {name = "nvim_lua";}
      {name = "vsnip";}
      {name = "path";}
      {name = "buffer";}
    ];
    mapping = {
      "<tab>" = "cmp.mapping.select_next_item()";
      "<s-tab>" = "cmp.mapping.select_prev_item()";
      "<C-Space>" = "cmp.mapping.complete()";
    };
  };
}
