{pkgs, ...}: {
  imports = [
    ./completion.nix
    ./languages.nix
    ./oil.nix
    ./spectre.nix
  ];

  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        viAlias = true;
        vimAlias = true;

        lsp = {
          enable = true;
        };

        git = {
          vim-fugitive.enalbe = true;
        };

        lazy.plugins = {
          oil = {
            package = pkgs.vimPlugins.oil-nvim;
            setupModule = "oil";
          };
        };

        telescope = {
          enable = true;
        };

        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
        };

        ui = {
          colorizer.enable = true;
        };
      };
    };
  };
}
