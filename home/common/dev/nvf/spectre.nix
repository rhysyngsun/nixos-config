{pkgs, ...}:
{
  programs.nvf.settings.vim = {
    lazy.plugins."nvim-spectre" = {
      package = pkgs.vimPlugins.nvim-spectre;
      setupModule = "spectre";
      setupOpts = {
        default = {
          search = "${pkgs.ripgrep}/bin/ripgrep";
          replace = "${pkgs.gnused}/bin/sed";
        };
      };
      keys = [
        {
          mode = ["n" "v"];
          action = "<cmd>lua require('spectre').toggle()<cr>";
          key = "<leader>fss";
        }
        {
          mode = ["n" "v"];
          action = "<cmd>lua require('spectre').open_visual({select_word=true})<cr>";
          key = "<leader>fsw";
        }
        {
          mode = ["n" "v"];
          action = "<cmd>lua require('spectre').open_file_search({select_word=true})<cr>";
          key = "<leader>fsf";
        }
      ];
    };
  };
}
