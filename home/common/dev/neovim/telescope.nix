{ pkgs, ... }:
{
  programs.nixvim = {
    keymaps = [
      {
        mode = "n";
        key = "<leader>pp";
        action = "require'telescope'.extensions.projects.projects";
        lua = true;
      }
      {
        mode = "n";
        key = "<leader><leader>";
        action = "<Cmd>Telescope frecency<CR>";
      }
    ];

    plugins.telescope = {
      enable = true;
      keymaps = {
        "<leader>pf" = "find_files";
        "<leader>ps" = "live_grep";
        "<leader>pS" = "grep_string";
        "<leader>pg" = "git_files";
        "<leader>pb" = "buffers";
      };

      extensions = {
        frecency.enable = true;
      };
    };

    extraPackages = with pkgs; [
      ripgrep
    ];
  };
}
