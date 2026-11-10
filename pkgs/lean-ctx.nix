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

  # Since 3.12 the dashboard UI is a separate signed package (the Cockpit) that
  # the engine proxies to, and every install path for it reads these through
  # `option_env!` (`rust/src/core/intelligence_runtime/bootstrap.rs`). Upstream
  # sets them from CI variables that the release tarball does not carry, so a
  # plain source build reports `SourceBuild` and serves the install page
  # instead - `lean-ctx cockpit install` cannot help, it goes through the same
  # missing channel. The values are the public catalog URLs and signing root of
  # the official x86_64 build. `build.rs` admits the Cockpit pair only beside a
  # complete runtime triple, so both are set or neither is.
  #
  # The runtime triple also marks this a production host for the licence-bound
  # Intelligence Runtime. It is the same switch; with no licence nothing from
  # that catalog installs.
  env = {
    LEANCTX_PRODUCTION_RUNTIME_CHANNEL_URL = "https://api.leanctx.com/runtime/pro/catalog.json";
    LEANCTX_PRODUCTION_RUNTIME_CHANNEL_SIGNATURE_URL = "https://api.leanctx.com/runtime/pro/catalog.sig";
    LEANCTX_PRODUCTION_RUNTIME_CHANNEL_ROOT_KEY_HEX = "0bd980168214936eee63b74d8c747ce4ebb58a6f19047d379d8e606a6b85ca6b";
    LEANCTX_PRODUCTION_COCKPIT_CHANNEL_URL = "https://api.leanctx.com/runtime/cockpit/channel.json";
    LEANCTX_PRODUCTION_COCKPIT_CHANNEL_SIGNATURE_URL = "https://api.leanctx.com/runtime/cockpit/channel.sig";
  };

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
