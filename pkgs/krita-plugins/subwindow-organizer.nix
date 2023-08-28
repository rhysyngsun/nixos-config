{ stdenv, fetchFromGitHub }:
let
  pname = "subwindow-organizer";
  version = "0.0.0";
in stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "wojtryb";
    repo = "kritaSubwindowOrganizer";
    rev = "9e6fc6d5f867015c94ab96408f73153e80b01a70";
    hash = "sha256-1IzJEzgy3q9x8nkJYCB265hopfNd7NhJ+9NZEAy6LUA=";
  };

  installPhase = ''
    install -m555 -D -d $src/subwindowOrganizer/ $out/share/krita/pykrita/subwindowOrganizer/
    install -m555 -D $src/subwindowOrganizer.desktop $out/share/krita/pykrita/subwindowOrganizer.desktop
  '';
}