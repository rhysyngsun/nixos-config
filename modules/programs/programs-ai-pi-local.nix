{ ... }:
{
  flake.modules.homeManager.programs-ai-pi-local =
    {
      config,
      pkgs,
      pkgs-unstable,
      lib,
      ...
    }:
    let
      cfg = config.programs.pi-coding-agent;
      jsonFormat = pkgs.formats.json { };

      # `settings.packages` is the declarative source of truth for which pi
      # extensions should exist. Writing it to settings.json only *declares*
      # them - pi resolves each one from <configDir>/npm/node_modules/<name>,
      # so the package still has to be fetched for the extension to load.
      declaredSources = cfg.settings.packages or [ ];

      isNpm = lib.hasPrefix "npm:";
      npmSpecs = map (lib.removePrefix "npm:") (lib.filter isNpm declaredSources);
      otherSources = lib.filter (s: !isNpm s) declaredSources;

      # The key npm records in package.json's `dependencies`, which is the spec
      # minus any version range: "pi-lmstudio@1.5.0" -> "pi-lmstudio", and
      # "@bacnh85/pi-plan" -> "@bacnh85/pi-plan" (leading @ is a scope, not a
      # version separator).
      depKeyOf =
        spec:
        let
          parts = lib.splitString "@" spec;
        in
        if lib.hasPrefix "@" spec then "@" + lib.elemAt parts 1 else lib.head parts;

      # The version half of the same split, or "" for an unpinned spec. With
      # `--save-exact` below this is exactly what npm records as the dependency
      # value, which is what makes the reconcile version-aware.
      depVersionOf =
        spec:
        let
          parts = lib.splitString "@" spec;
          after = if lib.hasPrefix "@" spec then lib.drop 2 parts else lib.tail parts;
        in
        if after == [ ] then "" else lib.concatStringsSep "@" after;

      npmDir = "${cfg.configDir}/npm";

      # Renders one `[key]=value` line per declared npm spec, for a bash
      # associative-array literal.
      bashAssoc =
        f:
        lib.concatMapStringsSep "\n  " (
          spec: "[${lib.escapeShellArg (depKeyOf spec)}]=${lib.escapeShellArg (f spec)}"
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
          #
          # --save-exact is what makes the drift check below work: without it
          # npm records "^1.2.3" and a pinned spec never compares equal to it.
          npm_args=(
            --prefix "$npm_dir"
            --save
            --save-exact
            --no-audit
            --no-fund
            --legacy-peer-deps
          )

          # key -> full spec to hand npm, and key -> pinned version ("" when the
          # spec carries none, which means "any installed version will do").
          declare -A want_spec=(
            ${if npmSpecs == [ ] then "" else bashAssoc (s: s)}
          )
          declare -A want_ver=(
            ${if npmSpecs == [ ] then "" else bashAssoc depVersionOf}
          )

          ${lib.optionalString (otherSources != [ ]) /* bash */ ''
            warn "pi-sync-extensions: not npm sources, leaving them alone:"
            ${lib.concatMapStringsSep "\n" (s: "warn \"   ? ${s}\"") otherSources}
          ''}

          mkdir -p "$npm_dir"
          if [ ! -e "$pkg_json" ]; then
            printf '%s\n' '{"name":"pi-extensions","private":true,"dependencies":{}}' >"$pkg_json"
          fi

          declare -A have_ver=()
          while IFS=$'\t' read -r key version; do
            [ -n "$key" ] && have_ver["$key"]="$version"
          done < <(jq -r '(.dependencies // {}) | to_entries[] | "\(.key)\t\(.value)"' "$pkg_json")

          # A version change is an install, never an install *and* a remove -
          # the uninstall pass runs first and would undo it in the same run.
          install_specs=()
          if (( ''${#want_spec[@]} > 0 )); then
            while read -r key; do
              [ -n "$key" ] || continue
              if [[ ! -v have_ver["$key"] ]]; then
                install_specs+=("''${want_spec[$key]}")
              elif [ -n "''${want_ver[$key]}" ] && [ "''${have_ver[$key]}" != "''${want_ver[$key]}" ]; then
                printf 'pi-sync-extensions: %s %s -> %s\n' \
                  "$key" "''${have_ver[$key]}" "''${want_ver[$key]}"
                install_specs+=("''${want_spec[$key]}")
              fi
            done < <(printf '%s\n' "''${!want_spec[@]}" | LC_ALL=C sort)
          fi

          remove_names=()
          if (( ''${#have_ver[@]} > 0 )); then
            while read -r key; do
              [ -n "$key" ] || continue
              [[ -v want_spec["$key"] ]] || remove_names+=("$key")
            done < <(printf '%s\n' "''${!have_ver[@]}" | LC_ALL=C sort)
          fi

          if (( ''${#remove_names[@]} == 0 && ''${#install_specs[@]} == 0 )); then
            printf 'pi-sync-extensions: %s extension(s) already in sync.\n' \
              "''${#want_spec[@]}"
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

      # pi ships no permission system of its own - docs/security.md is explicit
      # that "it does not ask for approval before every tool call" - so the
      # policy below is what makes the `guardrails` rule in programs-ai-claude
      # ("ask before committing or pushing") enforceable here too.
      #
      # Pattern maps are ORDERED: last match wins. builtins.toJSON emits
      # attribute names sorted, so the order pi sees is alphabetical. That is
      # correct for the `family *` style used throughout - a space (0x20) sorts
      # before any letter, so `git *` always precedes `git push *`, and `*`
      # (0x2A) precedes everything alphanumeric. INVARIANT: never add a pattern
      # whose broader sibling would sort after it. Check the generated JSON,
      # not this file.
      bashPolicy = {
        "*" = "ask";

        # Translated from programs.claude-code.settings.permissions.allow in
        # programs-ai-claude.nix: `Bash(uv run:*)` is this file's "uv run *".
        # The two lists will drift; they are not yet shared.
        "command -v *" = "allow";
        "docker compose *" = "allow";
        "find *" = "allow";
        "gitleaks *" = "allow";
        "grep *" = "allow";
        "pls *" = "allow";
        "pre-commit *" = "allow";
        "prek *" = "allow";
        "rg *" = "allow";
        "uv run *" = "allow";

        # gh: read-only and branch-shaped subcommands only. Anything that
        # comments, merges or edits falls through to the "*" ask.
        "gh issue *" = "allow";
        "gh repo *" = "allow";
        "gh run *" = "allow";
        "gh stack *" = "allow";

        # git: no bare `git *` allow. `checkout` and `restore` are absent on
        # purpose - both silently discard working-tree changes - and so are
        # `commit` and `push`, which the guardrails rule requires a prompt for.
        "git add *" = "allow";
        "git checkout -b *" = "allow";
        "git diff *" = "allow";
        "git fetch *" = "allow";
        "git switch *" = "allow";
        "git worktree *" = "allow";

        # In-place edits are a write dressed as a read; claude-code asks for
        # these too. Sorts after the bare "sed *" allow, so it wins.
        "sed *" = "allow";
        "sed -i*" = "ask";
      };

      permissionConfig = {
        # Records every request and denial under
        # <configDir>/extensions/pi-permission-system/logs/.
        permissionReviewLog = true;

        # pi-lean-ctx runs in `replace` mode (see its config below), which
        # suppresses the native read/bash/ls/find/grep in favour of ctx_*. That
        # hands the shell to ctx_shell, which without this hint would be gated
        # as a generic extension tool and skip the bash rules entirely.
        shellTools = {
          ctx_shell = {
            commandArgument = "command";
          };
        };

        permission = {
          # Least privilege: anything not named below prompts.
          "*" = "ask";

          # Reads, both the native tools and their ctx_* substitutes.
          read = "allow";
          ls = "allow";
          find = "allow";
          grep = "allow";
          ctx_read = "allow";
          ctx_ls = "allow";
          ctx_find = "allow";
          ctx_grep = "allow";

          # Spelled out rather than left to the "*" fallback so that a later
          # loosening of that fallback cannot silently take writes with it.
          write = "ask";
          edit = "ask";
          ctx_edit = "ask";

          # Reaching outside the working tree is worth a prompt on its own.
          external_directory = "ask";

          # Cross-cutting: applies to every tool and to bash at once, and a
          # deny here cannot be overridden by a per-tool allow.
          path = {
            "*" = "allow";
            "*.env" = "deny";
            "*.env.*" = "deny";
            "*.env.example" = "allow";
            "*/.ssh/*" = "deny";
            "*/sops/age/*" = "deny";
            "*/.pi/agent/auth.json" = "deny";
            "*/secrets/secrets.yaml" = "deny";
          };

          bash = bashPolicy;
        };
      };
    in
    {
      home.packages = with pkgs; [
        lmstudio
        # Exposed so the reconcile can be rerun by hand, e.g. after being
        # offline during a switch.
        syncScript
        lean-ctx
      ];

      programs.git.ignores = [ ".agents/" ];
      programs.pi-coding-agent = {
        enable = true;
        package = pkgs-unstable.pi-coding-agent;
        extraPackages = with pkgs; [
          nodejs
          python3
          # pi-lean-ctx shells out to the engine and resolves it from PATH -
          # its fallback chain probes ~/.cargo/bin, ~/.local/bin and
          # /usr/local/bin before giving up on a bare "lean-ctx", and none of
          # those exist here. extraPackages rather than home.packages so the
          # binary is found however pi was launched.
          lean-ctx
        ];
        settings = {
          theme = "dark";

          # Explicit rather than implicit: in -p/json/rpc modes, where the trust
          # prompt cannot be shown, "ask" means project resources are *skipped*
          # rather than loaded. Worth stating so it is not mistaken for a
          # missing decision. (docs/security.md, "Project trust without an
          # interactive prompt".)
          defaultProjectTrust = "ask";
          enableSkillCommands = true;

          # Pinned on purpose. The reconciler above only reinstalls when the
          # recorded version differs from the declared one, so without versions
          # here an extension is whatever npm happened to resolve the day it
          # was first installed and never moves again. Bump with
          #   npm --prefix ~/.pi/agent/npm outdated
          packages = [
            "npm:@narumitw/pi-plan-mode@0.59.4"
            # "npm:@bacnh85/pi-plan"
            # Ships in lockstep with pkgs.lean-ctx (see nvfetcher.toml), so it
            # is derived from it rather than written out - the npm half cannot
            # drift away from the engine it drives.
            "npm:pi-lean-ctx@${pkgs.lean-ctx.version}"
            "npm:pi-lmstudio@1.5.0"
            "npm:pi-subagents@0.80.0"
            "npm:pi-subdir-context@1.1.7"
            "npm:@juicesharp/rpiv-ask-user-question@2.7.1"
            "npm:@gotgenes/pi-permission-system@41.0.0"
            # pi has no WebSearch/WebFetch of its own. Works keyless via Exa;
            # optional provider keys live in ~/.pi/agent/web-search.json, which
            # is deliberately left unmanaged.
            "npm:pi-web-access@0.44.0"
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

      # NB: no leading "~" in these keys. home-manager does not expand one, so a
      # "~/.pi/..." key writes to a literal `~` directory under $HOME and the
      # file never reaches pi.
      home.file.".pi/agent/extensions/pi-lean-ctx/config.json".source =
        jsonFormat.generate "pi-lean-ctx-config.json"
          {
            mode = "replace";
            enableMcp = true;
            toolProfile = "power";
            binary = "${pkgs.lean-ctx}/bin/lean-ctx";
            env = {
              LEAN_CTX_COMPRESSION = "aggressive";
            };
          };

      home.file.".pi/agent/extensions/pi-permission-system/config.json".source =
        jsonFormat.generate "pi-permission-system-config.json" permissionConfig;

      home.sessionVariables = {
        LEAN_CTX_BIN = "${pkgs.lean-ctx}/bin/lean-ctx";
      };

      # `defaultPlanTools` *replaces* plan mode's default selection
      # (read/bash/grep/find/ls), which pi-lean-ctx's `replace` mode suppresses
      # anyway - hence naming the ctx_* substitutes here rather than leaving it
      # unset, which would select nothing.
      #
      # Only tools that actually exist belong in this list: pi-plan-mode
      # silently drops unknown names, so a phantom entry looks configured and
      # does nothing. pi-lean-ctx 3.10.5 registers exactly six tools, and
      # `toolProfile` does not add any - it only forwards
      # LEAN_CTX_TOOL_PROFILE to the engine. ctx_edit is left out on purpose:
      # it writes, and plan mode's blocked-builtin rule only covers the native
      # `edit`/`write`, so an extension write tool named here would be
      # selectable.
      home.file.".pi/agent/pi-plan-mode-src.json".source = jsonFormat.generate "pi-plan-mode.json" {
        defaultPlanTools = [
          # The read-only substitutes for pi's suppressed builtins.
          "ctx_read"
          "ctx_grep"
          "ctx_find"
          "ctx_ls"
          # The shell substitute. Note that plan mode's safe-command filter
          # keys off the tool *name*, so it covers `bash` and `powershell`
          # only - ctx_shell runs unfiltered and is gated by
          # pi-permission-system's bash rules instead.
          "ctx_shell"
          # Inert while `replace` mode suppresses it. Named so that softening
          # pi-lean-ctx to `additive` restores the filtered bash rather than
          # silently leaving plan mode with ctx_shell as its only shell.
          "bash"
        ];
      };

      # pi-plan-mode reads pi-plan-mode.json and expects to be able to write it
      # back, so it cannot be the read-only store symlink directly. Copying the
      # *resolved* source with an explicit mode is what makes it writable - a
      # plain `cp` of the symlink leaves it 0444.
      #
      # This clobbers the file on every switch by design: the nix declaration
      # wins, and any preference changed inside the TUI is transient.
      home.activation.piPlanModeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run install -m 644 \
          "$(readlink -f ${config.home.homeDirectory}/.pi/agent/pi-plan-mode-src.json)" \
          ${config.home.homeDirectory}/.pi/agent/pi-plan-mode.json
      '';
    };
}
