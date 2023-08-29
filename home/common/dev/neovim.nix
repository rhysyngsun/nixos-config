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

  # xdg.configFile."nvim" = {
  #   source = inputs.nvchad;
  #   recursive = true;
  # };

  # xdg.configFile."nvim/" = {
  #   source = ./nvim;
  #   recursive = true;
  # };
}