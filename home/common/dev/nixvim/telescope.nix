{ pkgs, ... }:
{
  programs.nixvim = {
    keymaps = [
      {
        mode = "n";
        key = "<leader>rs";
        action = "<CMD>LspRestart<CR>";
      }
      {
        mode = "n";
        key = "<leader>fb";
        action = {
          __raw = "vim.lsp.buf.format";
        };
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

      settings = {
        defaults = {
          layout_strategy = "vertical";
          layout_config = {
            width = 0.8;
            height = 0.9;
          };
          selection_caret = " ";
        };
        pickers = {
          buffers = {
            mappings = {
              i = {
                "<c-d>" = {
                  __raw = "require('telescope.actions').delete_buffer"; 
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

    extraPackages = with pkgs; [ ripgrep ];
  };
}
