{
  config,
  pkgs-stable,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.types) package;

  cfg = config.vim.languages.noy;

in
{
  options.vim.languages.noy = {
    enable = mkEnableOption "noy language support";

    treesitter = {
      enable = mkEnableOption "noy treesitter" // {
        default = config.vim.languages.enableTreesitter;
      };

      # Not an upstream nvim-treesitter grammar, so there is nothing for
      # `mkGrammarOption` to look up - build it from the nvfetcher-pinned
      # source in `additions`, which is stable-only (see programs-neovim.nix).
      package = mkOption {
        description = "noy treesitter grammar";
        type = package;
        default = pkgs-stable.tree-sitter-noy;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.treesitter.enable {
      # Neovim has no built-in `noy` filetype, so nothing ever sets it and the
      # `FileType *` autocommand that calls `vim.treesitter.start()` never
      # fires. Without this the parser and queries below are dead weight.
      vim.filetype.extension.noy = "noy";

      vim.treesitter.enable = true;
      vim.treesitter.grammars = [ cfg.treesitter.package ];

      # gnames/tree-sitter-noy ships `queries/highlights.scm`, but it is a
      # zero-byte file, and `grammarToPlugin` installs it anyway - so the
      # grammar alone highlights nothing. Ship a real query and take base
      # priority over the empty one with `loadtype = "overwrite"`
      # (nvf prepends overwrite queries to the runtimepath, and
      # `vim.treesitter.query.get_files` picks the first non-`; extends` file
      # in runtimepath order as the base).
      # vim.treesitter.queries = [
      #   {
      #     filetypes = [ "noy" ];
      #     loadtype = "extends";
      #     type = "highlights";
      #     query = ''
      #       [
      #         "-"
      #         "+"
      #         "*"
      #         "/"
      #         "="
      #         "=="
      #       ] @operator
      #       ["fn"] @keyword.function
      #
      #       ["(" ")"] @punctuation.bracket
      #       ["{" "}"] @punctuation.bracket
      #     '';
      #   }
      # ];
    })
  ]);
}
