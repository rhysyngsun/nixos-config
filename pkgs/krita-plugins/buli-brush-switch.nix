{ stdenv, fetchFromGitHub }:
let
  pname = "buli-brush-switch";
  version = "1.0.0";
in stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "Grum999";
    repo = "BuliBrushSwitch";
    rev = "${version}";
    hash = "sha256-xi+1JJX3xZK05hE0HyW3O54HHrCbtKGrNBFvB+33E4Q=";
  };

  installPhase = ''
    install -m555 -D $src/bulibrushswitch/bulibrushswitch.action $out/share/krita/actions/bulibrushswitch.action
    install -m555 -D $src/bulibrushswitch/bulibrushswitch.desktop $out/share/krita/pykrita/bulibrushswitch.desktop
    install -m555 -D -d $src/bulibrushswitch/bulibrushswitch/ $out/share/krita/pykrita/
  '';
}