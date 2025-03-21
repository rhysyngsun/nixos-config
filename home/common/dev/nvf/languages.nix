{
  programs.nvf.settings.vim = {
    languages = {
      enableDAP = true;
      enableExtraDiagnostics = true;
      enableFormat = true;
      enableLSP = true;
      enableTreesitter = true;

      go = {
        enable = true;
      };
      lua = {
        enable = true;
      };
      nix = {
        enable = true;
      };
      markdown = {
        enable = true;
      };
      python = {
        enable = true;
      };
      rust = {
        enable = true;
      };
      sql = {
        enable = true;
      };
      ts = {
        enable = true;
      };
      yaml = {
        enable = true;
      };
      zig = {
        enable = true;
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "gd";
        action = "<CMD>lua vim.lsp.buf.hover<CR>";
      }
      {
        mode = "n";
        key = "gD";
        action = "<CMD>lua vim.lsp.buf.declaration<CR>";
      }
      {
        mode = "n";
        key = "gi";
        action = "<CMD>lua vim.lsp.buf.implementation<CR>";
      }
    ];
  };
}
