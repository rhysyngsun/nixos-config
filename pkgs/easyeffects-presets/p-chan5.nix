{ stdenv, fetchFromGitHub }:
let
  pname = "p-chan5";
  version = "0.0.0-unstable";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "p-chan5";
    repo = "EasyPulse";
    rev = "94e97f4fcb3790d98a7d08f4a8c9b39823b91a41";
    hash = "sha256-JDqWeOceabWehvq9csq9JQQlpSFdv+whe3Qek7oy7wQ=";
  };

  installPhase = ''
    install -m555 -D -d $src $out
  '';
}
