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

  cfg = config.vim.languages.peg;

in
{
  options.vim.languages.peg = {
    enable = mkEnableOption "Peg language support";

    treesitter = {
      enable = mkEnableOption "Peg treesitter" // {
        default = config.vim.languages.enableTreesitter;
      };

      # Not an upstream nvim-treesitter grammar, so there is nothing for
      # `mkGrammarOption` to look up - build it from the nvfetcher-pinned
      # source in `additions`, which is stable-only (see programs-neovim.nix).
      package = mkOption {
        description = "Peg treesitter grammar";
        type = package;
        default = pkgs-stable.tree-sitter-peg;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.treesitter.enable {
      # Neovim has no built-in `peg` filetype, so nothing ever sets it and the
      # `FileType *` autocommand that calls `vim.treesitter.start()` never
      # fires. Without this the parser and queries below are dead weight.
      vim.filetype.extension.peg = "peg";

      vim.treesitter.enable = true;
      vim.treesitter.grammars = [ cfg.treesitter.package ];

      # gnames/tree-sitter-peg ships `queries/highlights.scm`, but it is a
      # zero-byte file, and `grammarToPlugin` installs it anyway - so the
      # grammar alone highlights nothing. Ship a real query and take base
      # priority over the empty one with `loadtype = "overwrite"`
      # (nvf prepends overwrite queries to the runtimepath, and
      # `vim.treesitter.query.get_files` picks the first non-`; extends` file
      # in runtimepath order as the base).
      vim.treesitter.queries = [
        {
          filetypes = [ "peg" ];
          loadtype = "overwrite";
          type = "highlights";
          query = ''
            (comment) @comment @spell

            ; Go preamble: `package foo` + `type Engine Peg { ... }`
            (package_clause) @keyword
            (package_identifier) @module
            "type" @keyword.type
            (type_spec name: (type_identifier) @type.definition)
            (type_spec type: (type_identifier) @type)
            (block (type_identifier) @type)

            ; A rule name on the left of `<-` is an alias for `identifier`, so
            ; definitions and references are distinguishable.
            (rule_def_name) @function
            (identifier) @function.call

            (operator_assign) @operator
            (and_predicate) @operator
            (not_predicate) @operator
            (quantifier) @operator
            "/" @operator

            (single_quoted) @string
            (double_quoted) @string
            (char_class) @string.regexp
            (any_char) @character.special

            ["(" ")"] @punctuation.bracket
            ["{" "}"] @punctuation.bracket
          '';
        }
      ];
    })
  ]);
}
