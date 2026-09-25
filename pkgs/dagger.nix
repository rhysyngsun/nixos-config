# The Dagger CLI, built from source out of the dagger/dagger monorepo rather
# than taken from the official `dl.dagger.io` tarballs. Only `cmd/dagger` is
# built - the monorepo's other ten commands are engine-internal.
{
  lib,
  buildGoModule,
  installShellFiles,
  source,
}:
buildGoModule {
  pname = "dagger";
  # nvfetcher keeps the tag's `v` (see the comment in nvfetcher.toml); the
  # ldflags below want it back, so keep both spellings.
  version = lib.removePrefix "v" source.version;
  inherit (source) src;

  vendorHash = "sha256-9qN+33ThqbL+Kju1RvpctL904cAE3zgQRpf2WNjGjz4=";

  subPackages = [ "cmd/dagger" ];

  # `engine.Version` and `engine.Tag` are filled at link time - left unset the
  # binary reports an empty version and `engine/version.go`'s init() collapses
  # every minimum-version check down to it.
  ldflags = [
    "-s"
    "-w"
    "-X github.com/dagger/dagger/engine.Version=${source.version}"
    "-X github.com/dagger/dagger/engine.Tag=${source.version}"
  ];

  # The repo's Go tests drive a real engine over a container runtime.
  doCheck = false;

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd dagger \
      --bash <($out/bin/dagger completion bash) \
      --fish <($out/bin/dagger completion fish) \
      --zsh <($out/bin/dagger completion zsh)
  '';

  meta = {
    description = "Platform for orchestrating the delivery of applications";
    homepage = "https://dagger.io";
    license = lib.licenses.asl20;
    mainProgram = "dagger";
    platforms = lib.platforms.unix;
  };
}
