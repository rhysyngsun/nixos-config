{ stdenv, lib, fetchurl, libxcrypt, openssl, autoPatchelfHook }:
stdenv.mkDerivation rec {

  pname = "pants";
  version = "0.10.4";

  src = fetchurl {
    url = "https://github.com/pantsbuild/scie-pants/releases/download/v${version}/scie-pants-linux-${stdenv.hostPlatform.linuxArch}";
    hash = "sha256-CHP9hhMT/WLkeB7lNwvlmtihz21Dho6T7PQhtzqZP38=";
  };

  buildInputs = [
    libxcrypt
    openssl
  ];
  nativeBuildInputs = [
    autoPatchelfHook
  ];

  dontUnpack = true;
  installPhase = ''
    runHook preInstall
    install -D $src $out/bin/pants
    chmod +x $out/bin/pants
    runHook postInstall
  '';

  meta = with lib; {
    description = "A a fast, scalable, user-friendly build system for codebases of all sizes";
    homepage = "https://github.com/pantsbuild/scie-pants";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
