{pkgs, ...}:
{
  programs.nvf.vim.lazy.plugins.spectre = {
    package = pkgs.vimPlugins.nvim-spectre;
    setupModule = "spectre";
    setupOpts = {
      default = {
        search = "${pkgs.ripgrep}/bin/ripgrep";
        replace = "${pkgs.oxi}/bin/oxi";
      };
    };
    keys = [
      {
        action = "<cmd>lua require('spectre').toggle()<cr>";
        key = "<leader>fss";
      }
      {
        action = "<cmd>lua require('spectre').open_visual({select_word=true})<cr>";
        key = "<leader>fsw";
      }
      {
        action = "<cmd>lua require('spectre').open_file_search({select_word=true})<cr>";
        key = "<leader>fsf";
      }
    ];
  };
}
