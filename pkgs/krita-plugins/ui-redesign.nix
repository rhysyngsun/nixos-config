{ stdenv, fetchFromGitHub }:
let
  pname = "ui-redesign";
  version = "0.0.0";
in stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "veryprofessionaldodo";
    repo = "Krita-UI-Redesign";
    rev = "be0304169465403aa004b678baea8786a62fc78f";
    hash = "sha256-MhUOecrUD5d+mcri+5AkNUlmDLowgXQxk0AcjS+/A1U=";
  };

  installPhase = ''
    install -m555 -D $src/krita-redesign.desktop $out/share/krita/pykrita/krita-redesign.desktop
    install -m555 -D $src/KritaRedesign.colors $out/share/krita/pykrita/KritaRedesign.colors
    install -m555 -D -d $src/krita-redesign/ $out/share/krita/pykrita/krita-redesign/
  '';
}