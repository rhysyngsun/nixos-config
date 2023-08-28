{ stdenv, fetchFromGitHub }:
let
  pname = "shapes-and-layers";
  version = "0.10.0";
in stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "KnowZero";
    repo = "Krita-ShapesAndLayers-Plugin";
    rev = "616281d0641f130c76935b60cbc3e89fafb8b718";
    hash = "sha256-Hbd+wv72yihcRzXGtFCz2+1cbUYPt75jQMzPRjLNhXM=";
  };
  installPhase = ''
    install -m555 -D -d $src/shapesandlayers/ $out/share/krita/pykrita/
  '';
}