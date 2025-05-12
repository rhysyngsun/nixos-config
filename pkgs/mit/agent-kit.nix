{ stdenv, source }:
stdenv.mkDerivation {
  inherit (source) pname version src;
  phases = [ "installPhase" ];

  installPhase = ''
    mkdir $out
    cp -R $src $out
  '';
}
