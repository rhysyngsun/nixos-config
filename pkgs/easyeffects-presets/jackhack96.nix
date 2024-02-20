{ stdenv, fetchFromGitHub }:
let
  pname = "jackhack96";
  version = "0.0.0-unstable";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "JackHack96";
    repo = "EasyEffects-Presets";
    rev = "834bc5007b976250190cd71937c8c22f182d2415";
    hash = "sha256-jMTQp2wdPOno/3FckKeOAV+ZMoalaWXIQkg+Aai3jaU=";
  };

  installPhase = ''
    install -m555 -D $src/*.json -t $out/output/
    install -m555 -D $src/irs/* -t $out/irs/
  '';
}
