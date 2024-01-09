{
  programs.nixvim = {
    plugins.lsp = {
      enable = true;
      servers = {
#        bashls.enable = true;
        gopls.enable = true;
        lua-ls.enable = true;
        html.enable = true;
        jsonls.enable = true;
        nil_ls.enable = true;
        ruff-lsp.enable = true;
        rust-analyzer = {
          enable = true;
          installCargo = true;
          installRustc = true;
        };
        tailwindcss.enable = true;
        tsserver.enable = true;
        yamlls.enable = true;
      };
    };
  };
}
