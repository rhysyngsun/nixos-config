# witan — MIT ODL's agent memory / task-coordination MCP server, plus its
# sibling witan-code (tree-sitter code graph, mounted in-process by
# `witan serve`). Both live in the agent-kit monorepo's uv workspace, so this
# builds them from that checkout's own uv.lock rather than resolving from PyPI
# at runtime the way upstream's `uvx --from git+...` invocation does.
{
  lib,
  callPackage,
  python313,
  omnigraph,
  git,
  makeWrapper,
  runCommand,
  source,
  inputs,
}:
let
  # agent-kit's root pyproject.toml is a *virtual* uv workspace: it declares no
  # package of its own, only the five members. Loading from the repo root gives
  # the single unified lock spanning witan-council, witan-code, witan-core and
  # agent-config-kit.
  workspace = inputs.uv2nix.lib.workspace.loadWorkspace { workspaceRoot = source.src; };

  # Every third-party dependency in that lock ships a wheel, so preferring
  # wheels means only the workspace members themselves build from source (via
  # hatchling, from pyproject-build-systems) and no per-package fixups are
  # needed. python313 rather than the default python3 (3.14): the compiled deps
  # — pydantic-core, caio, rpds-py, tree-sitter* — all publish cp313 wheels.
  overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

  pythonSet =
    (callPackage inputs.pyproject-nix.build.packages { python = python313; }).overrideScope
      (
        lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.default
          overlay
        ]
      );

  venv = pythonSet.mkVirtualEnv "witan-env" {
    witan-council = [ ];
    witan-code = [ ];
  };
in
runCommand "witan-${source.version}"
  {
    nativeBuildInputs = [ makeWrapper ];
    passthru = { inherit venv workspace pythonSet; };
    meta = {
      description = "Agent memory, planning and collaboration graph, exposed over MCP";
      homepage = "https://github.com/mitodl/agent-kit/tree/main/mcp/servers/witan";
      license = lib.licenses.bsd3;
      mainProgram = "witan";
      platforms = lib.platforms.linux;
    };
  }
  ''
    mkdir -p $out/bin
    for prog in witan witan-code; do
      makeWrapper ${venv}/bin/$prog $out/bin/$prog \
        --prefix PATH : ${
          lib.makeBinPath [
            omnigraph
            git
          ]
        }
    done
  ''
