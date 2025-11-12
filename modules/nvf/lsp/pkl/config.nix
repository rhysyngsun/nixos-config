{
  config,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.nvim.lua) toLuaObject;
  inherit (lib.nvim.dag) entryAfter;

  cfg = config.vim.lsp.pkl-lsp;
in {
  config = mkIf cfg.enable (mkMerge [
    {
      vim = {
        startPlugins = [
          "none-ls-nvim"
          "plenary-nvim"
        ];

        # null-ls implies that LSP is already being set up
        # as it will hook into LSPs to receive information.
        lsp.enable = true;

        pluginRC.pkl-lsp = entryAfter ["lsp-setup"] ''

        '';
      };
    }
  ]);
}
