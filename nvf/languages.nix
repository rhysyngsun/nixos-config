{ pkgs, lib, ... }: let
  inherit (lib.generators) mkLuaInline;
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
      pkl = {
        enable = true;
        lsp.server = "brine";
      };
      python = {
        enable = true;
        lsp.servers = ["basedpyright"];
      };
      rust.enable = true;
      sql.enable = true;
      templ.enable = true;
      typescript.enable = true;
      yaml.enable = true;
      zig.enable = true;
    };
    lsp.servers.sqls = {
      cmd = lib.mkForce ["${pkgs.sqls}/bin/sqls" "-config" ''string.format("%s/.sqls.yml", vim.fn.getcwd())''];
      on_attach = mkLuaInline /* lua */ ''function() 
        client.server_capabilities.execute_command = true
        on_attach_keymaps(client, bufnr)
        require'sqls'.setup{}
      end'';
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
