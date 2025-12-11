{ config, pkgs, lib, ... }: let
  inherit (lib.lists) isList;
  inherit (lib.nvim.lua) expToLua;
in {
  config.vim = {
    languages = {
      enableDAP = true;
      enableExtraDiagnostics = true;
      enableFormat = true;
      enableTreesitter = true;

      go.enable = true;
      html.enable = true;
      java.enable = true;
      lua.enable = true;
      nix.enable = true;
      markdown.enable = true;
      pkl.enable = true;
      python = {
        enable = true;
        lsp.package = pkgs.basedpyright;
      };
      rust.enable = true;
      sql.enable = true;
      templ.enable = true;
      ts.enable = true;
      yaml.enable = true;
      zig.enable = true;
    };

    lsp.lspconfig.sources = {
      sql-lsp = let
        cfg = config.vim.languages.sql;
      in lib.mkForce /* lua */ ''
        lspconfig.sqls.setup {
          on_attach = function(client)
            client.server_capabilities.execute_command = true
            on_attach_keymaps(client, bufnr)
            require'sqls'.setup{}
          end,
          cmd = ${
          if isList cfg.lsp.package
          then expToLua cfg.lsp.package
          else ''{ "${cfg.lsp.package}/bin/sqls", "-config", string.format("%s/.sqls.yml", vim.fn.getcwd()) }''
        }
        }

      '';
    };

    keymaps = [
      {
        mode = "n";
        key = "gd";
        action = "vim.lsp.buf.hover";
        lua = true;
      }
      {
        mode = "n";
        key = "gD";
        action = "vim.lsp.buf.declaration";
        lua = true;
      }
      {
        mode = "n";
        key = "gi";
        action = "vim.lsp.buf.implementation";
        lua = true;
      }
    ];

    lazy.plugins.nvim-whichpy = {
      package = pkgs.vimUtils.buildVimPlugin {
        pname = "nvim-whichpy";
        version = "latest";
        src = pkgs.fetchFromGitHub {
          owner = "neolooong";
          repo = "whichpy.nvim";
          rev = "8bc5ca0d22d0f6686425c905850cf6ddeda51445";
          hash = "sha256-Hm72XJN45o8sqGufLp/18tusfcpsumnOvQc1gsZZerQ=";
        };
        doCheck = false;
      };

      setupModule = "whichpy";

      ft = [ "python" ];

      cmd = [ "WhichPy" ];
    };
  };
}
