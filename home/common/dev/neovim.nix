{pkgs, inputs, ...}:
{
  programs.neovim = {
    enable = true;
    
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # plugins = with pkgs.vimPlugins; [
    #   auto-pairs
    #   fzf-vim
    #   lightline-vim
    #   nerdtree

    #   vim-polyglot
    #   vim-gitgutter
    #   vim-nix
    # ];

    extraPackages = with pkgs; [
      gcc
      unzip
      tree-sitter
      nodejs
      nixpkgs-fmt
      black
      nodePackages.typescript-language-server
      nodePackages.vscode-langservers-extracted
      ripgrep
      fd
    ];

    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
  };

  xdg.configFile."nvim/init.lua" = {
    source = inputs.nvchad + "/init.lua";
    recursive = true;
  };

  xdg.configFile."nvim/lua/core" = {
    source = inputs.nvchad + "/lua/core";
    recursive = true;
  };

  xdg.configFile."nvim/lua/plugins" = {
    source = inputs.nvchad + "/lua/plugins";
    recursive = true;
  };
}