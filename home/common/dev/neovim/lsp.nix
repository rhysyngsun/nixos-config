{
  programs.nixvim = {
    plugins.lsp = {
      enable = true;
      servers = {
#        bashls.enable = true;
        gopls.enable = true;
        lua-ls.enable = true;
        html = {
          enable = true;
          filetypes = [ "html" "templ"];
        };

        htmx = {
          enable = true;
          filetypes = [ "html" "templ"];
        };
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
          filetypes = ["templ"];
        };
        tsserver.enable = true;
        yamlls.enable = true;
      };
    };
  };
}
