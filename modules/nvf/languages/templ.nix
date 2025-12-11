{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (builtins) attrNames;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.lists) isList;
  inherit (lib.types) enum either listOf package str;
  inherit (lib.nvim.types) mkGrammarOption;
  inherit (lib.nvim.lua) expToLua;
  inherit (lib.nvim.dag) entryBefore;

  cfg = config.vim.languages.templ;

  defaultServer = "templ-lsp";
  servers = {
    templ-lsp = {
      package = pkgs.templ;
      lspConfig = ''
        lspconfig.templ_lsp.setup {
          capabilities = capabilities;
          on_attach = default_on_attach;
        }
      '';
    };
  };

in {
  options.vim.languages.templ = {
    enable = mkEnableOption "Templ language support";

    treesitter = {
      enable = mkEnableOption "Templ treesitter" // {default = config.vim.languages.enableTreesitter;};

      package = mkGrammarOption pkgs "templ";
    };

    lsp = {
      enable = mkEnableOption "Templ LSP support" // {default = config.vim.lsp.enable;};

      server = mkOption {
        description = "Templ LSP server to use";
        type = enum (attrNames servers);
        default = defaultServer;
      };

      package = mkOption {
        description = "Templ LSP server package, or the command to run as a list of strings";
        example = ''[lib.getExe pkgs.jdt-language-server " - data " " ~/.cache/jdtls/workspace "]'';
        type = either package (listOf str);
        default = servers.${cfg.lsp.server}.package;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.treesitter.enable {
      vim.treesitter.enable = true;
      vim.treesitter.grammars = [cfg.treesitter.package];

      vim.pluginRC.templ_lsp = entryBefore ["templ-lsp"] /* lua */ ''
        require("lspconfig.configs").templ_lsp = {
          default_config = {
            cmd = ${
              if isList cfg.lsp.package
              then expToLua cfg.lsp.package
              else ''{"${cfg.lsp.package}/bin/templ", "lsp"}''
            },
            filetypes = { "templ" };
            root_dir = function(fname)
              return lspconfig.util.find_git_ancestor(fname) or vim.loop.os_homedir()
            end;
            settings = {};
          };
        }
      '';
    })

    (mkIf cfg.lsp.enable {
      vim.lsp.lspconfig.enable = true;
      vim.lsp.lspconfig.sources.templ-lsp = servers.${cfg.lsp.server}.lspConfig;
    })
  ]);
}
