{ tree-sitter, source }:
tree-sitter.buildGrammar {
  language = "peg";
  inherit (source) src version;
}
