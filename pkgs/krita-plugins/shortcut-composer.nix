{ stdenv, fetchFromGitHub }:
let
  pname = "shortcut-composer";
  version = "1.4.0";
in stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "wojtryb";
    repo = "Shortcut-Composer";
    rev = "v${version}";
    hash = "sha256-KAzBzRxeCCAZX0+Ra/m3PxOsk0RGAbOL0uxM4Rm/LBs=";
  };
  installPhase = ''
    install -m555 -D -d $src/shortcut_composer/ $out/share/krita/pykrita/shortcut_composer
    install -m555 -D $src/shortcut_composer.desktop $out/share/krita/pykrita/shortcut_composer.desktop
  '';
}