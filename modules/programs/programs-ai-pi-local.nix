{ ... }:
{
  flake.modules.homeManager.programs-ai-pi-local =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.programs.pi-coding-agent;

      # `settings.packages` is the declarative source of truth for which pi
      # extensions should exist. Writing it to settings.json only *declares*
      # them - pi resolves each one from <configDir>/npm/node_modules/<name>,
      # so the package still has to be fetched for the extension to load.
      declaredSources = cfg.settings.packages or [ ];

      isNpm = lib.hasPrefix "npm:";
      npmSpecs = map (lib.removePrefix "npm:") (lib.filter isNpm declaredSources);
      otherSources = lib.filter (s: !isNpm s) declaredSources;

      # The key npm records in package.json's `dependencies`, which is the spec
      # minus any version range: "pi-lmstudio@^1.5.0" -> "pi-lmstudio", and
      # "@bacnh85/pi-plan" -> "@bacnh85/pi-plan" (leading @ is a scope, not a
      # version separator).
      depKeyOf =
        spec:
        let
          parts = lib.splitString "@" spec;
        in
        if lib.hasPrefix "@" spec then "@" + lib.elemAt parts 1 else lib.head parts;

      npmDir = "${cfg.configDir}/npm";

      wantEntries = lib.concatMapStringsSep "\n        " (
        spec: "[${lib.escapeShellArg (depKeyOf spec)}]=${lib.escapeShellArg spec}"
      ) npmSpecs;

      # Reconciles <configDir>/npm against `settings.packages`. Deliberately
      # uses npm rather than `pi install`/`pi uninstall`: those rewrite
      # settings.json, which home-manager owns as a read-only store symlink.
      syncScript = pkgs.writeShellApplication {
        name = "pi-sync-extensions";
        runtimeInputs = with pkgs; [
          jq
          nodejs
          coreutils
          gnugrep
        ];
        text = /* bash */ ''
          #!/usr/bin/env bash

          npm_dir=${lib.escapeShellArg npmDir}
          pkg_json="$npm_dir/package.json"

          warn() { printf '%s\n' "$*" >&2; }

          # Extensions declare @earendil-works/pi-coding-agent as a peer dep,
          # but the agent is supplied by the pi binary rather than from
          # node_modules, so those ranges are decorative - and they routinely
          # conflict with each other (npm ERESOLVE). pi installs through them,
          # so we have to as well or a valid extension set fails to install.
          npm_args=(
            --prefix "$npm_dir"
            --save
            --no-audit
            --no-fund
            --legacy-peer-deps
          )

          declare -A want=(
            ${if npmSpecs == [ ] then "" else wantEntries}
          )

          ${lib.optionalString (otherSources != [ ]) /* bash */ ''
            warn "pi-sync-extensions: not npm sources, leaving them alone:"
            ${lib.concatMapStringsSep "\n" (s: "warn \"   ? ${s}\"") otherSources}
          ''}

          mkdir -p "$npm_dir"
          if [ ! -e "$pkg_json" ]; then
            printf '%s\n' '{"name":"pi-extensions","private":true,"dependencies":{}}' >"$pkg_json"
          fi

          tmp=$(mktemp -d)
          trap 'rm -rf "$tmp"' EXIT

          jq -r '(.dependencies // {}) | keys[]' "$pkg_json" \
            | LC_ALL=C sort >"$tmp/have"

          : >"$tmp/want"
          if (( ''${#want[@]} > 0 )); then
            printf '%s\n' "''${!want[@]}" | LC_ALL=C sort >"$tmp/want"
          fi

          mapfile -t to_install < <(comm -23 "$tmp/want" "$tmp/have")
          mapfile -t to_remove < <(comm -13 "$tmp/want" "$tmp/have")

          install_specs=()
          for key in ''${to_install[@]+"''${to_install[@]}"}; do
            [ -n "$key" ] && install_specs+=("''${want[$key]}")
          done

          remove_names=()
          for key in ''${to_remove[@]+"''${to_remove[@]}"}; do
            [ -n "$key" ] && remove_names+=("$key")
          done

          if (( ''${#remove_names[@]} == 0 && ''${#install_specs[@]} == 0 )); then
            printf 'pi-sync-extensions: %s extension(s) already in sync.\n' \
              "$(wc -l <"$tmp/want")"
            exit 0
          fi

          # npm needs the network; a failure here must not brick a switch.
          status=0

          if (( ''${#remove_names[@]} > 0 )); then
            warn ""
            warn "=================================================================="
            warn " pi-sync-extensions: UNINSTALLING ''${#remove_names[@]} undeclared extension(s)"
            warn ""
            warn " These are installed in $npm_dir but are NOT declared in"
            warn " programs.pi-coding-agent.settings.packages. Add them there to"
            warn " keep them."
            warn ""
            for name in "''${remove_names[@]}"; do
              warn "   - $name"
            done
            warn "=================================================================="
            warn ""
            npm uninstall "''${npm_args[@]}" "''${remove_names[@]}" || {
              warn "pi-sync-extensions: npm uninstall failed; left as-is."
              status=1
            }
          fi

          if (( ''${#install_specs[@]} > 0 )); then
            printf 'pi-sync-extensions: installing %s declared extension(s):\n' \
              "''${#install_specs[@]}"
            for spec in "''${install_specs[@]}"; do
              printf '   + %s\n' "$spec"
            done
            npm install "''${npm_args[@]}" "''${install_specs[@]}" || {
              warn "pi-sync-extensions: npm install failed (offline?); not installed."
              status=1
            }
          fi

          if (( status != 0 )); then
            warn "pi-sync-extensions: finished with errors - rerun 'pi-sync-extensions'."
          fi
          exit 0
        '';
      };
    in
    {
      home.packages = with pkgs; [
        lmstudio
        # Exposed so the reconcile can be rerun by hand, e.g. after being
        # offline during a switch.
        syncScript
      ];

      programs.git.ignores = [ ".agents/" ];
      programs.pi-coding-agent = {
        enable = true;
        package = pkgs.pkgs-unstable.pi-coding-agent;
        extraPackages = with pkgs; [
          nodejs
          python3
        ];
        settings = {
          theme = "dark";
          packages = [
            "npm:@bacnh85/pi-plan"
            "npm:pi-lmstudio"
            "npm:pi-subagents"
            "npm:pi-subdir-context"
          ];
        };
        models = {
          providers = {
            lmstudio = {
              baseUrl = "http://localhost:1234/v1";
              api = "openai-completions";
            };
          };
        };
      };

      # Runs after writeBoundary so settings.json is already linked into place.
      home.activation.piSyncExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${lib.getExe syncScript}
      '';
    };
}
