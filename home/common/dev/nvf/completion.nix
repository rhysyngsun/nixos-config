{
  programs.nvf.settings.vim.autocomplete = {
    enableSharedCmpSources = true;
    blink-cmp = {
      enable = true;
      friendly-snippets.enable = true;
      setupOpts = {
        keymap.preset = "default";
        completion = {
          menu = {
            auto_show = true;
          };
        };
        completion = {
          menu = {
            border = "single";
          };
          documentation = {
            window = {
              border = "single";
            };
          };
        };
        signature = {
          enabled = true;
          window = {
            border = "single";
          };
        };
        sources = {
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
          providers.lsp = {
            fallbacks = [ ];
          };
        };
      };
    };
  };
}
