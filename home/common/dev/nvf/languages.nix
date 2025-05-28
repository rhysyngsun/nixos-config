{pkgs, ...}: {
  programs.nvf.settings.vim = {
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
      python = {
        enable = true;
        lsp.package = pkgs.unstable.basedpyright;
      };
      rust.enable = true;
      sql.enable = true;
      ts.enable = true;
      yaml.enable = true;
      zig.enable = true;
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

    lazy.plugins."whichpy.nvim" = {
      package = pkgs.unstable.vimPlugins.whichpy-nvim;

      setupModule = "whichpy";

      ft = ["python"];

      cmd = ["WhichPy"];
    };
  };
}
