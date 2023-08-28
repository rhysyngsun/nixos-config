{ stdenv, fetchFromGitHub }:
let
  pname = "compact-brush-toggler";
  version = "0.0.0";
in stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "kaichi1342";
    repo = "CompactBrushToggler";
    rev = "e2770b0595f7a911fd3b74f8c5fe5800c7944510";
    hash = "sha256-eoEVhGBY9RyJ9ZHmWZgF7+RzTbIj9yPzoQp9VNY3L9E=";
  };

  installPhase = ''
    install -m555 -D -d $src/compactbrushtoggler/ $out/share/krita/pykrita/
  '';
}