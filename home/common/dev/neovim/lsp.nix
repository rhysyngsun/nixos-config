{
  programs.nixvim = {
    filetype.extension = {
      ftl = "html";
    };

    plugins.lsp = {
      enable = true;

      capabilities = ''
        local language_servers = require("lspconfig").util.available_servers() -- or list servers manually like {'gopls', 'clangd'}
        for _, ls in ipairs(language_servers) do
            require('lspconfig')[ls].setup({
                capabilities = capabilities
                -- you can add other fields for setting up lsp server in this table
            })
        end
      '';

      servers = {
        #        bashls.enable = true;
        gopls.enable = true;
        lua-ls.enable = true;
        html = {
          enable = true;
          filetypes = [ "html" "templ" ];
        };

        htmx = {
          enable = true;
          filetypes = [ "html" "templ" ];
        };
        java-language-server.enable = true;
        jsonls.enable = true;
        nil_ls.enable = true;
        ruff-lsp.enable = true;
        rust-analyzer = {
          enable = true;
          installCargo = true;
          installRustc = true;
        };
        tailwindcss = {
          enable = true;
          filetypes = [ "templ" "javascript" "typescript" "react" ];
          extraOptions = {
            init_options = {
              userLanguages = { templ = "html"; };
            };
          };
        };
        templ = {
          enable = true;
          filetypes = [ "templ" ];
        };
        tsserver.enable = true;
        yamlls = {
          enable = true;
          extraOptions.capabilities.textDocument.foldingRange = {
            dynamicRegistration = false;
            lineFoldingOnly = true;
          };
        };
      };
    };
  };
}
