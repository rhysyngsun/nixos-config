{
  lib,
  rustPlatform,
  makeWrapper,
  onnxruntime,
  versionCheckHook,
  source,
}:
rustPlatform.buildRustPackage {
  inherit (source) pname version src;

  # The release tarball is the whole monorepo; the engine is one Rust workspace
  # inside it. Its `default-members = ["."]` keeps a plain build scoped to the
  # `lean-ctx` bin, skipping the SDK and grammar-addon members.
  sourceRoot = "${source.pname}-${source.version}/rust";

  # nvfetcher extracts `rust/Cargo.lock` at repin time (`cargo_lock` in
  # nvfetcher.toml), so the vendor set is derived from the lock that ships with
  # `src` instead of a hand-written `cargoHash` that goes stale on every bump.
  # `outputHashes` is empty because the lock has no `source = "git+..."` entries.
  cargoLock = source.cargoLock."rust/Cargo.lock";

  nativeBuildInputs = [ makeWrapper ];

  # `ort` is compiled with `load-dynamic`, so nothing is fetched at build time
  # and libonnxruntime is resolved at runtime instead. Left unset the binary
  # would probe Nix profiles and /usr/lib and fail on a fresh machine, taking
  # the `embeddings` feature (and the knowledge/recall tools) with it.
  # `--set-default` so an operator ORT_DYLIB_PATH still wins, as upstream
  # documents.
  postInstall = ''
    wrapProgram $out/bin/lean-ctx \
      --set-default ORT_DYLIB_PATH ${onnxruntime}/lib/libonnxruntime.so
  '';

  # Upstream's suite spans ~3600 files and expects network, git fixtures and a
  # writable HOME. Packaging only needs the bin to run.
  doCheck = false;

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  meta = {
    description = "Context runtime for AI coding agents - compresses what the model reads";
    homepage = "https://github.com/yvgude/lean-ctx";
    license = lib.licenses.asl20;
    mainProgram = "lean-ctx";
    platforms = lib.platforms.linux;
  };
}
