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

  # The release tarball is flat (three binaries, no top-level directory), so the
  # default single-directory sourceRoot detection has nothing to descend into.
  sourceRoot = ".";

  # The tarball also carries `omnigraph-server` (another ~197M), which only
  # serves the `http://` remote-team tier, and since 0.10.0 a third binary,
  # `omnigraph-azure-admission` - that third one is why the asset grew, and it
  # is inert here because Azure is not a supported backend. witan's local-disk
  # and s3:// modes drive the `omnigraph` CLI alone, so both are left out; add
  # `omnigraph-server` back here if a remote store is ever self-hosted from
  # this machine.
  installPhase = ''
    runHook preInstall
    install -Dm755 omnigraph -t $out/bin
    runHook postInstall
  '';
}
