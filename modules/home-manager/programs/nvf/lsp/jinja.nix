{ config, pkgs, lib, ... }:
let
  inherit (builtins) attrNames;
  inherit (lib.options) mkEnableOption mkOption literalExpression;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.lists) isList;
  inherit (lib.types) enum either listOf package str bool;
  inherit (lib.nvim.lua) expToLua;

  cfg = config.programs.nvf.settings;
  jinja_cfg = cfg.vim.languages.jinja;
in {
  options.progams.nvf.settings.vim.languages.jinja = {
    
    enable = mkEnableOption "Jinja language support";
    
    lsp = {
      enable = mkEnableOption "Jinja LSP support" // {default = cfg.vim.lsp.enable;};

      package = mkOption {
        description = "jinja LSP server package, or the command to run as a list of strings";
        example = ''[lib.getExe pkgs.jdt-language-server "-data" "~/.cache/jdtls/workspace"]'';
        type = either package (listOf str);
        default = pkgs.jinja-lsp;
      };
    };
  };

  config.progams.nvf.settings = mkIf jinja_cfg.enable (mkMerge [
    (mkIf jinja_cfg.lsp.enable {
      vim.lsp.lspconfig.enable = true;
      vim.lsp.lspconfig.sources.jinja-lsp = ''
        lspconfig.jinja_lsp.setup{
          capabilities = capabilities;
          on_attach = default_on_attach;
          cmd = ${
          if isList jinja_cfg.lsp.package
          then expToLua jinja_cfg.lsp.package
          else ''{"${jinja_cfg.lsp.package}/bin/jinja-lsp"}''
        }
        }
      '';
    })
  ]);
}
