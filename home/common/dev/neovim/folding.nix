{ pkgs, ... }:
{
  programs.nixvim = {
    plugins.nvim-ufo = {
      enable = true;

      providerSelector = builtins.readFile ./plugin/ufo.providerSelector.lua;
    };
    extraConfigLua = ''
      vim.o.foldcolumn = '0'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
      vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

      vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
      vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
    '';

    extraPlugins = with pkgs.vimPlugins; [
      {
        plugin = statuscol-nvim;
        config = builtins.readFile ./plugin/statuscol.lua;
      }
    ];
  };
}
