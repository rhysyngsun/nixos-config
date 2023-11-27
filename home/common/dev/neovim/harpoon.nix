{
  programs.nixvim = {
    plugins.harpoon = {
      enable = true;
      enableTelescope = true;

      keymaps = {
        addFile = "<leader>a";
        cmdToggleQuickMenu = "<C-e>";
        navFile = {
          "1" = "<C-l>";
          "2" = "<C-u>";
          "3" = "<C-y>";
          "4" = "<C-;>";
        };
      };
    };
  };
}