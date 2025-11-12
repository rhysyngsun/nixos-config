{stdenv, makeWrapper, jdk24_headless, source, ...}:
let
  inherit (source) pname version src;
  jdk = jdk24_headless;
in
  stdenv.mkDerivation {
    inherit pname version src;

    buildInputs = [jdk];
    nativeBuildInputs = [makeWrapper];

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/share/java $out/bin
      cp $src $out/share/java/${pname}-${version}.jar

      # shellcheck disable=SC1072,SC1073,SC1009
      makeWrapper ${jdk}/bin/java $out/bin/${pname} \
        --add-flags "-jar $out/share/java/${pname}-${version}.jar"
    '';
  }
