{
  stdenv,
  autoPatchelfHook,
  source,
  ...
}:
let
  inherit (source) pname version src;
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  # The release tarball is flat (two binaries, no top-level directory), so the
  # default single-directory sourceRoot detection has nothing to descend into.
  sourceRoot = ".";

  # The tarball also carries `omnigraph-server` (another ~197M), which only
  # serves the `http://` remote-team tier. witan's local-disk and s3:// modes
  # drive the `omnigraph` CLI alone, so it is left out; add it back here if a
  # remote store is ever self-hosted from this machine.
  installPhase = ''
    runHook preInstall
    install -Dm755 omnigraph -t $out/bin
    runHook postInstall
  '';
}
