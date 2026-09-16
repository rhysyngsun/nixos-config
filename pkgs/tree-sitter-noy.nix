{ tree-sitter, source }:
tree-sitter.buildGrammar {
  language = "noy";
  inherit (source) src version;
}
