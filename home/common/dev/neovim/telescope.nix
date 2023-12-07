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
    ];

    plugins.telescope = {
      enable = true;
      keymaps = {
        "<leader>pf" = "find_files";
	      "<leader>ps" = "live_grep";
        "<leader>pg" = "git_files";
        "<leader>pb" = "buffers";
      };

      extensions = {
        project-nvim.enable = true;
        
      };
    };

    extraPackages = with pkgs; [
      ripgrep
    ];
  };
}
