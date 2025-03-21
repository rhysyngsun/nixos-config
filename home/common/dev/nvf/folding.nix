{pkgs, lib, ... }: let
  inherit (lib.generators) mkLuaInline;
in {
  programs.nvf.settings.vim = {
    luaConfigPost = ''
      vim.o.foldcolumn = '1'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
      vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

      vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
      vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
    '';

    ui.nvim-ufo = {
      enable = true;
      setupOpts = {
        provider_selector =  mkLuaInline ''
          function(bufnr, filetype, buftype)
            return {'treesitter', 'indent'}
          end
        '';
      };
    };

    lazy.plugins."statuscol.nvim" = {
      package = pkgs.vimPlugins.statuscol-nvim;
      setupModule = "statuscol";
      setupOpts = {
        relculright = true;
        segments = mkLuaInline ''
          {
            { text = { require("statuscol.builtin").foldfunc }, click = "v:lua.ScFa" },
            { text = { "%s" }, click = "v:lua.ScSa" },
            { text = { require("statuscol.builtin").lnumfunc, " " }, click = "v:lua.ScLa" },
          }
        '';
      };

      event = ["BufEnter"];
    };
  };
}
