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
        # frecency.enable = true;
      };
      settings = {
        defaults = {
          layout_config = {
            width = 0.999;
            height = 0.999;
          };
          selection_caret = " ";
        };
        pickers = {
          buffers = {
            mappings = {
              i = {
                "<c-d>" = {
                  __raw = "require('telescope.actions').delete_buffer + require('telescope.actions').move_to_top";
                };
              };
            };
          };
          find_files = {
			      find_command = {
              __raw = ''{ "rg", "--files", "--hidden", "--glob", "!**/.git/*" }'';
            };
          };
        };
      };
    };

    extraPackages = with pkgs; [
      ripgrep
    ];
  };
}
