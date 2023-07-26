{ stdenv, lib, fetchFromGitHub, makeWrapper, libGL, zlib, xorg, python39, pipenv, which }:
let
  pname = "blender-launcher";
  version = "1.15.1";
in stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "DotBow";
    repo = "Blender-Launcher";
    rev = "v${version}";
    hash = "sha256-0BY8VcbFhvkM+9pyHq7OhYOmLi0aWDUf3FJ1XkNtygo=";
  };

  patches = [];

  buildInputs = [
    zlib
    python39
    pipenv
    which
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  format = "other";

  buildPhase = ''
    export PIPENV_VENV_IN_PROJECT=1

    pipenv install
    
  '';

  installPhase = ''
    install -m755 -D Blender\ Launcher $out/bin/blender-launcher
  '';

  postFixup = ''
    wrapProgram $out/bin/blender-launcher \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
      libGL
      xorg.libxcb
    ]}
  '';
}