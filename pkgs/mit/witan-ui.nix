# The witan web UI — the page `witan ui` serves, plus the MCP Apps widgets.
#
# Built out of the same pinned agent-kit checkout as witan itself rather than
# from a release artifact: upstream never publishes the bundle on its own, it
# only ships inside the witan wheel (ui/package.json: "Built into
# ../witan/ui_dist and shipped inside the witan wheel"). Since the bundle is
# git-ignored, the pinned checkout carries no ui_dist and neither does a wheel
# built from it, so `witan ui` against the local store ends in "No UI bundle
# was built". witan.nix grafts this output back into witan-council.
{
  lib,
  stdenvNoCC,
  nodejs,
  importNpmLock,
  source,
}:
let
  uiRoot = "${source.src}/mcp/servers/witan/ui";
in
stdenvNoCC.mkDerivation {
  pname = "witan-ui";
  version = source.version;
  src = source.src;

  # importNpmLock rather than buildNpmPackage's npmDepsHash: the hash is
  # derived from package-lock.json, so every `just update-pkgs -f odl-agent-kit`
  # that touches the lock would otherwise fail the build until someone
  # hand-copied a new hash out of the error. This reads the lock's own
  # integrity digests instead, which makes a repin a one-file change again.
  nativeBuildInputs = [
    nodejs
    importNpmLock.hooks.linkNodeModulesHook
  ];
  npmDeps = importNpmLock.buildNodeModules {
    npmRoot = uiRoot;
    inherit nodejs;
  };

  # Note there is no `dontConfigure`: linkNodeModulesHook installs itself as a
  # preConfigure hook, and skipping the phase skips the hook, leaving the build
  # with no node_modules at all.
  sourceRoot = "${source.src.name}/mcp/servers/witan/ui";

  buildPhase = ''
    runHook preBuild

    # vite.config.ts writes outDir = "../witan/ui_dist" — deliberately inside
    # the Python package, since `packages = ["witan"]` is what puts files in the
    # wheel. That is one level ABOVE sourceRoot, and stdenv's unpackPhase only
    # makes sourceRoot itself writable, so rolldown fails with a bare
    # "Permission denied (os error 13)" without this.
    chmod -R u+w ..

    # `vite build && node build-widgets.js`. The second half is not optional
    # decoration: it emits widgets/*.html, each inlined into a single file by
    # vite-plugin-singlefile, and witan/ui_widgets.py binds a tool to its
    # widget only when that file exists — so skipping it silently drops the
    # widget surface rather than failing.
    npm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -r ../witan/ui_dist $out
    runHook postInstall
  '';

  meta = {
    description = "Web UI and MCP Apps widgets for the witan graph";
    homepage = "https://github.com/mitodl/agent-kit/tree/main/mcp/servers/witan/ui";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
}
