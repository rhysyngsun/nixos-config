{
  config,
  pkgs,
  pkgs-stable,
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

  cfg = config.vim.languages.pkl;

  defaultServer = "pkl-lsp";
  servers = {
    pkl-lsp = {
      package = pkgs-stable.pkl-lsp;
      lspConfig = ''
        lspconfig.gopls.setup {
          capabilities = capabilities;
          on_attach = default_on_attach;
          cmd = ${
          if isList cfg.lsp.package
          then expToLua cfg.lsp.package
          else ''{"${cfg.lsp.package}/bin/pkl-lsp"}''
        },
        }
      '';
    };
  };

in {
  options.vim.languages.pkl = {
    enable = mkEnableOption "Pkl language support";

    treesitter = {
      enable = mkEnableOption "Pkl treesitter" // {default = config.vim.languages.enableTreesitter;};

      package = mkGrammarOption pkgs "pkl";
    };

    lsp = {
      enable = mkEnableOption "Pkl LSP support" // {default = config.vim.lsp.enable;};

      server = mkOption {
        description = "Pkl LSP server to use";
        type = enum (attrNames servers);
        default = defaultServer;
      };

      package = mkOption {
        description = "Pkl LSP server package, or the command to run as a list of strings";
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
    })

    (mkIf cfg.lsp.enable {
      vim.lsp.lspconfig.enable = true;
      vim.lsp.lspconfig.sources.pkl-lsp = servers.${cfg.lsp.server}.lspConfig;
    })
  ]);
}
