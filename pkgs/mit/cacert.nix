{ stdenv, fetchurl }:
let
  pname = "mit-cacert";
  version = "2023.07.26";
in
stdenv.mkDerivation {
  inherit version pname;

  src = fetchurl {
    url = "https://ca.mit.edu/mitca.crt";
    hash = "sha256-K/sIXlEs6s+NbptIvG/FioJpYm0UKwMuvSjEYmvrmKc=";
  };

  phases = [ "installPhase" ];

  installPhase = ''
    install -D $src $out/etc/ssl/certs/mitca.crt
  '';
}
