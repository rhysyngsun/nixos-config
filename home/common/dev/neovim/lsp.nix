{
  programs.nixvim = {
    filetype.extension = {
      ftl = "html";
      mjml = "html";
    };

    plugins.lsp = {
      enable = true;

      servers = {
        bashls.enable = true;
        biome.enable = true;
        docker-compose-language-service.enable = true;
        gopls.enable = true;
        lua-ls.enable = true;
        html = {
          enable = true;
          filetypes = [
            "html"
            "templ"
            "mjml"
          ];
        };

        htmx = {
          enable = true;
          filetypes = [
            "html"
            "templ"
          ];
        };
        java-language-server.enable = true;
        jsonls.enable = true;
        nil-ls.enable = true;
        pylsp = {
          enable = true;
          settings.plugins = {
            jedi_completion.enable = true;
            jedi_definition.enable = true;
            pylsp_mypy.enabled = true;
            ruff.enabled = true;
          };
        };
        ruff-lsp.enable = true;
        rust-analyzer = {
          enable = true;
          installCargo = true;
          installRustc = true;
        };
        tailwindcss = {
          enable = true;
          filetypes = [
            "templ"
            "javascript"
            "typescript"
            "react"
          ];
          extraOptions = {
            init_options = {
              userLanguages = {
                templ = "html";
              };
            };
          };
        };
        templ.enable = true;
        tsserver.enable = true;
        yamlls = {
          enable = true;
          extraOptions.capabilities.textDocument.foldingRange = {
            dynamicRegistration = false;
            lineFoldingOnly = true;
          };
        };
        zls.enable = true;
      };
    };

    keymaps = [
      {
        key = "<leader>ca";
        action = "<CMD>lua vim.lsp.buf.code_action()<CR>";
        mode = ["n" "v"];
      }
    ];
  };
}
