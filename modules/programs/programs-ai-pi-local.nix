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
      #
      # A `packages` entry is either a bare source string or the object form
      # `{ source, skills, ... }`, which filters which of the package's resources
      # pi loads (settings-schema.js PackageSourceSchema). Only the source half
      # is npm's business, so flatten to it before anything below looks at the
      # list - `isNpm` would otherwise be handed an attrset and throw.
      sourceOf = entry: if lib.isAttrs entry then entry.source else entry;
      declaredSources = map sourceOf (cfg.settings.packages or [ ]);

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
        # hands the shell to pi-lean-ctx, which exposes it under TWO names:
        # `ctx_shell` (the extension's own tool) and `shell` (an alias bridged
        # from the engine, upstream `registered::shell_alias::ShellAliasTool`).
        # Both reach the same handler.
        #
        # Naming them here is what subjects them to `bashPolicy`; without the
        # hint they are gated as generic extension tools and skip the bash
        # rules entirely. `shell` additionally carries no destructiveHint
        # upstream - it is absent from lean-ctx's DESTRUCTIVE_TOOL_NAMES while
        # `ctx_shell` is present - so nothing else would catch it either.
        shellTools = {
          ctx_shell = {
            commandArgument = "command";
            workdirArgument = "cwd";
          };
          shell = {
            commandArgument = "command";
            workdirArgument = "cwd";
          };
        };

        permission = {
          # Least privilege: anything not named below prompts.
          "*" = "ask";

          # The native reads. Inert while pi-lean-ctx runs in `replace` mode,
          # but correct if it is ever softened to `additive`.
          read = "allow";
          ls = "allow";
          find = "allow";
          grep = "allow";

          # pi's lean-ctx surface is two layers and `ctx_*` covers both:
          #   - 7 tools the extension registers itself, shelling out to the
          #     lean-ctx CLI: ctx_shell, ctx_read, ctx_ls, ctx_find, ctx_grep,
          #     lean_ctx, ctx_edit. These are NOT MCP tools, so an MCP
          #     tools/list probe does not show them - they are real all the
          #     same, and the four read ones used to be listed here
          #     individually. Subsumed now; do not re-add them as "missing".
          #   - 15 bridged from the engine under `toolProfile = "standard"`
          #     (17 advertised, less ctx_read and ctx_shell which the extension
          #     already owns locally). Under the former "power" this layer was
          #     60 - the wildcard covers whichever profile is set.
          #
          # Three things make the wildcard safe, and all three are load-bearing:
          #   1. Surface keys are wildcard-matched, not exact (rule.ts
          #      ruleMatches -> wildcardMatch(rule.surface, surface)), and
          #      rules are last-match-wins in key order. builtins.toJSON sorts
          #      keys and "*" (0x2A) precedes every letter, so "ctx_*" always
          #      sorts before "ctx_patch" and the carve-outs below win. Same
          #      invariant as bashPolicy above - check the generated JSON.
          #   2. A `path` deny still wins: the path gate runs before the tool
          #      gate and short-circuits, so the secrets denies below hold.
          #   3. The two shell tools are pre-empted by `shellTools` above,
          #      which resolves them on the `bash` surface instead of their
          #      own - so this allow cannot un-gate a shell.
          #
          # `lean_ctx` is deliberately not matched here; it falls through to
          # the "*" ask rather than being guessed at.
          "ctx_*" = "allow";

          # Carve-outs from "ctx_*". Each writes outside ~/.lean-ctx, runs
          # arbitrary code, or dispatches to something this allowlist cannot
          # see. Tools that only persist lean-ctx's own state (ctx_cache,
          # ctx_index, ctx_memory, ctx_knowledge, ctx_session, ctx_summary,
          # ctx_ledger, ctx_artifacts, ctx_control, ctx_live_zone,
          # ctx_compress, ctx_proof, ctx_transcript_compact) are intentionally
          # left allowed - prompting for those is the friction being removed.
          ctx_patch = "ask"; # writes files (destructiveHint)
          ctx_execute = "ask"; # arbitrary code, 11 languages (destructiveHint)
          ctx_refactor = "ask"; # rename/move/safe_delete/inline rewrite source
          ctx_checkpoint = "ask"; # `restore` rewrites working-tree files
          ctx_skillify = "ask"; # `promote` writes .cursor/rules/skillify-*.mdc
          ctx_rules = "ask"; # `sync` rewrites agent rule files across tools
          ctx_pack = "ask"; # create/install/export/import/remove write files
          ctx_package = "ask"; # `save` writes a JSON bundle
          ctx_multi_repo = "ask"; # add_root/remove_root change reachable dirs
          ctx_call = "ask"; # invokes any of the 78 engine tools by name
          ctx_tools = "ask"; # `call` proxies arbitrary downstream MCP tools
          # Read-only, but reaches Jira/Postgres/REST with stored credentials.
          # Prompts under the standing "ask before connecting to a database or
          # service" guardrail, not because it mutates anything.
          ctx_provider = "ask";

          # Plan mode's clarifying-question tool. It only puts a prompt in
          # front of the user, so gating it behind a second prompt is pure
          # friction.
          plan_mode_question = "allow";
          plan_mode_complete = "allow";

          # rpiv-ask-user-question's tool, same reasoning: its whole effect is
          # showing the user a questionnaire. It was falling through to the "*"
          # ask, which meant a prompt to show a prompt.
          ask_user_question = "allow";

          # Systematic (@fro.bot/systematic) reaches its bundled skills through
          # TWO independent gates, and both were falling through to the "*"
          # ask - so loading one skill cost two prompts. Confirmed from
          # permissionReviewLog, which records them as separate requests:
          # surface "systematic_skill" (source tool_call, input
          # {"name":"systematic:using-systematic"}) and surface "skill"
          # (source skill_input, skillName "using-systematic").
          #
          # systematic_delegate, the extension's other tool, is deliberately
          # left to the "*" ask. It spawns its child session with
          # `noExtensions: true`, so pi-permission-system does not load in
          # that child and every tool the child is handed runs UNGATED - the
          # "unguarded child" this extension's own docs/subagent-integration.md
          # warns about. The prompt is the only thing between a delegate call
          # and an unpoliced session; do not promote it to allow.
          systematic_skill = "allow";

          # Nested pattern map keyed on skill name, like `bash` and `path`
          # (the surface is `skill`, singular - `skills` is not a surface).
          # Allowed wholesale because loading a skill only injects its
          # SKILL.md text into the prompt: it executes nothing by itself, and
          # every tool the skill subsequently reaches for is still gated by
          # the rules above. Gating it while `systematic_skill` is allowed
          # would just prompt twice for the same file read by another name.
          # Project-scope skills are in range here, but only for a project
          # `defaultProjectTrust` has already let through.
          skill = {
            "*" = "allow";
          };

          # Spelled out rather than left to the "*" fallback so that a later
          # loosening of that fallback cannot silently take writes with it.
          # ctx_edit is also a carve-out from "ctx_*" above.
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

      # LM Studio holds model weights in children of whichever process launched
      # it - the llmworker node process that carries the weights shares the
      # launcher's cgroup, and the bwrap FHS wrapper does not unshare it - so
      # confining the launcher confines the whole tree. Wrapping the binaries
      # rather than just the .desktop entry means terminal launches and `lms`
      # are covered too, and it avoids restating upstream's desktop metadata.
      lmstudioInSlice =
        let
          runInSlice = pkgs.writeShellScript "lmstudio-in-slice" ''
            real="$1"
            shift

            # Already inside the slice: don't nest a scope within a scope.
            if [[ -r /proc/self/cgroup && "$(</proc/self/cgroup)" == *lmstudio.slice* ]]; then
              exec "$real" "$@"
            fi

            # No reachable user manager - ssh without lingering, a rescue shell.
            # Run unconfined rather than refusing to start at all.
            if ! ${pkgs.systemd}/bin/systemctl --user show-environment >/dev/null 2>&1; then
              exec "$real" "$@"
            fi

            exec ${pkgs.systemd}/bin/systemd-run --user --quiet --collect \
              --slice=lmstudio.slice --scope -- "$real" "$@"
          '';
          wrap =
            name:
            pkgs.writeShellScriptBin name ''
              exec ${runInSlice} ${pkgs.lmstudio}/bin/${name} "$@"
            '';
        in
        # lndir keeps the first occurrence of each path, so the wrappers shadow
        # the package's own bin/ entries while icons, share/ and the .desktop
        # file (whose `Exec=lm-studio` resolves to the wrapper via PATH) still
        # come from the package.
        pkgs.symlinkJoin {
          name = "lmstudio-in-slice-${pkgs.lmstudio.version}";
          paths = [
            (wrap "lm-studio")
            (wrap "lms")
            pkgs.lmstudio
          ];
          meta.mainProgram = "lm-studio";
        };
    in
    {
      home.packages = with pkgs; [
        lmstudioInSlice
        # Exposed so the reconcile can be rerun by hand, e.g. after being
        # offline during a switch.
        syncScript
        # lean-ctx itself now comes from programs-ai-lean-ctx, which also owns
        # its daemon unit - it serves Claude Code as well as pi. The
        # `extraPackages` copy below is a different mechanism, not a duplicate.
      ];

      # LM Studio gets its own cgroup so an oversized model load degrades
      # inside it instead of letting the kernel OOM killer pick a victim by
      # RSS - which, under memory pressure, can just as easily be the
      # compositor. Pairs with the swapfile in services-swap.nix.
      systemd.user.slices.lmstudio = {
        Unit.Description = "LM Studio inference workload";
        Slice = {
          # Past this the kernel reclaims hard *within the slice*. Model
          # weights are clean mmap'd file pages, so reclaim is free - they just
          # page back in from the GGUF. Inference slows down instead of dying.
          MemoryHigh = "48G";
          # Hard ceiling, leaving headroom for the rest of the session.
          MemoryMax = "56G";
          MemorySwapMax = "64G";
        };
      };

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
          # pi shells out for the clipboard rather than linking a library, and
          # reports "Clipboard unavailable: install `wl-clipboard` (`wl-copy`)"
          # when it cannot find one. It picks the tool from the session: with
          # WAYLAND_DISPLAY set it tries wl-copy/wl-paste before any X11
          # fallback, and wl-paste is also what the image paste shortcut reads.
          # wl-clipboard was previously only inside the neovim wrapper
          # (nvf/default.nix), so nothing else on this machine could reach it.
          wl-clipboard
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

          # Leave the terminal as pi found it. pi runs fullscreen (the default
          # tuiMode), so the session itself lives on the alternate screen and
          # never touches scrollback - but on exit the default "transcript"
          # switches back to regular mode and repaints the whole conversation
          # into the main buffer. "resume-hint" skips that: the teardown writes
          # only the exit-alt-screen sequence, restoring the buffer untouched.
          # A one-line `To resume this session: ...` hint is still printed, and
          # a crash still forces the full transcript so diagnostics survive.
          fullscreenExitOutput = "resume-hint";

          # pi installs this as undici's bodyTimeout AND headersTimeout on its
          # global dispatcher (chunk-66G7ITPS.js:271,
          # DEFAULT_HTTP_IDLE_TIMEOUT_MS = 3e5), so the default gives up after
          # five minutes of socket silence. LM Studio emits no SSE bytes while
          # it buffers a tool call's arguments, and plan_mode_complete's one
          # argument is the entire plan (completion-tool.ts:6,
          # PLAN_MODE_MAX_CHARS = 50_000). At the 8-11 t/s this machine gets
          # from qwen3.5-9b that silent stretch runs past five minutes, undici
          # aborts the body with `TypeError: terminated`, and pi's auto-retry
          # replays the identical request twice more before surfacing
          # "Retry failed after 3 attempts: terminated". Ordinary text replies
          # stream continuously and never trip it, which is why only plan
          # finalization crashed.
          #
          # 30 min covers a max-length plan with margin while still catching a
          # genuinely wedged server - which "disabled" would not, and which
          # matters in -p/json/rpc modes where there is no Esc to abort.
          #
          # Must be declared here: settings.json is a read-only store symlink,
          # so pi's own /settings TUI cannot persist the value.
          httpIdleTimeoutMs = 1800000;

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
            # 2.12.0 is the floor: before it this package listed typebox in
            # `dependencies`, and pi warns at startup when an extension names a
            # host-provided package there rather than in peerDependencies with
            # a "*" range (dist/core/resource-loader.js:18-55) - an installed
            # copy can bypass the extension loader and duplicate the runtime
            # module.
            "npm:@juicesharp/rpiv-ask-user-question@2.13.9"
            "npm:@gotgenes/pi-permission-system@41.0.0"
            # pi has no WebSearch/WebFetch of its own. Works keyless via Exa;
            # optional provider keys live in ~/.pi/agent/web-search.json, which
            # is deliberately left unmanaged.
            "npm:pi-web-access@0.44.0"
            # TUI components: editor, message framing, statusline. Configured
            # interactively with /zentui, which *writes* ~/.pi/agent/zentui.json
            # - so that file stays unmanaged, the same way auth.json and
            # trust.json do. Declaring it here would make the store symlink
            # read-only and /zentui unable to save.
            "npm:pi-zentui@0.32.0"
            "npm:pi-inspector@0.1.3"
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

            # Was "power" (all 78 engine tools). That put 80 tool definitions
            # on the wire for a 46,936-token prompt - the prompt was mostly
            # tool schemas, generation decayed from 11.3 to 8.2 t/s as context
            # grew, and qwen3.5-9b burned turns on tool-schema validation
            # failures. "standard" bridges 17.
            #
            # Only "minimal", "standard" and "power" take effect. "lean" looks
            # like a fourth option and is not: resolveToolProfile maps anything
            # unrecognized to "lean", and config.ts:322-328 then declines to
            # forward LEAN_CTX_TOOL_PROFILE at all - so the engine falls back
            # to ~/.config/lean-ctx/config.toml, which is unmanaged here and
            # says "power". Setting "lean" would silently change nothing.
            #
            # Note "standard" also drops ctx_call, power's escape hatch to the
            # rest of the registry. Tools not bridged are reachable only as
            # `lean-ctx` subcommands through the shell tool.
            #
            # Authoritative listing: LEAN_CTX_TOOL_PROFILE=standard lean-ctx tools
            toolProfile = "standard";
            binary = "${pkgs.lean-ctx}/bin/lean-ctx";
            env = {
              LEAN_CTX_COMPRESSION = "aggressive";
            };
          };

      home.file.".pi/agent/extensions/pi-permission-system/config.json".source =
        jsonFormat.generate "pi-permission-system-config.json" permissionConfig;

      # Appended to pi's system prompt as an `<addendum>` section
      # (system-prompt.js:97-98), in every session, for every model. Kept short
      # for that reason - it is paid for on every turn.
      #
      # Aimed at local models served over `openai-completions`: qwen3.5-9b in
      # particular emits nested tool arguments as JSON strings and misreads the
      # resulting validation error. ask_user_question repairs that itself via
      # `prepareArguments`; plan_mode_question does not, hence the preference.
      #
      # Two limits worth knowing before trusting this:
      #   1. `<addendum>` sits in the system prompt, but pi-plan-mode injects
      #      its contract as a `role: "custom"` *conversation* message
      #      (mode-contract.ts:30-38) - so the plan prompt is far more recent
      #      and still names plan_mode_question. This argues upstream of it.
      #   2. A trusted project's `.pi/APPEND_SYSTEM.md` REPLACES this file
      #      rather than merging with it (resource-loader.js:955-965 returns on
      #      the first hit), silently and with no warning.
      home.file.".pi/agent/APPEND_SYSTEM.md".text = ''
        ## Tool-call arguments

        Tool arguments are a JSON object. Never pass a nested array or object as a
        JSON-encoded string: `{"questions": [{...}]}`, not `{"questions": "[{...}]"}`.

        When a tool call fails validation, read the reported path and keyword and fix
        exactly that. Do not restructure arguments the error did not name.

        ## Asking the user

        Prefer `ask_user_question` - it works in every mode, including Plan mode.
        `plan_mode_question` additionally requires a snake_case `id` on every question.
      '';

      home.sessionVariables = {
        LEAN_CTX_BIN = "${pkgs.lean-ctx}/bin/lean-ctx";
      };

      # `defaultPlanTools` *replaces* plan mode's default selection
      # (SAFE_BUILTIN_PLAN_TOOLS = read/bash/powershell/grep/find/ls), which
      # pi-lean-ctx's `replace` mode suppresses anyway - hence naming the
      # substitutes here rather than leaving it unset, which would select
      # nothing.
      #
      # Matching is exact: pi-plan-mode has no glob support (tool-selection.ts
      # uses Set.has), and unknown names are dropped from the active policy
      # and shown in the UI as "pending registration". That listing is the
      # typo detector for this block - after a switch, an entry still showing
      # as pending is a name that does not exist.
      #
      # The list is the no-repo-write subset of pi's two-layer lean-ctx
      # surface: the extension's own read tools plus the engine tools bridged
      # by `toolProfile = "standard"`. The bar is stricter than the permission
      # carve-outs above because plan mode does not inspect arguments for
      # non-builtin tools - it classifies them "user-opt-in" and trusts them
      # wholesale - so anything with even one write action is excluded, even
      # when that write only touches ~/.lean-ctx. Of the 17 tools `standard`
      # advertises that rules out ctx_knowledge (remember), ctx_session (save),
      # ctx_patch (anchored editor) and ctx_execute - plus, were the profile
      # ever widened again, ctx_index (build), ctx_summary (record),
      # ctx_memory (put/prune), ctx_artifacts (index/reindex/remove),
      # ctx_cache (clear), ctx_ledger (evict), ctx_live_zone (freeze),
      # ctx_control (pin/reset), ctx_compress, ctx_proof (write=true),
      # ctx_compile, ctx_transcript_compact - and everything carved out above.
      #
      # RE-DERIVE THIS WHEN lean-ctx IS BUMPED in nvfetcher.toml, OR WHEN
      # `toolProfile` CHANGES above. pi-lean-ctx on npm ships in lockstep with
      # that pin, so a bump moves both layers at once, and a name that
      # disappears fails silently. The authoritative listing for the engine
      # layer is `LEAN_CTX_TOOL_PROFILE=standard lean-ctx tools`; the
      # extension layer is profile-independent.
      home.file.".pi/agent/pi-plan-mode-src.json".source = jsonFormat.generate "pi-plan-mode.json" {
        defaultPlanTools = [
          # Not a lean-ctx tool - rpiv-ask-user-question's. Named here so there
          # is ONE question tool that works both inside and outside Plan mode.
          #
          # plan_mode_question cannot be dropped (required-tools.ts
          # withRequiredPlanModeTools force-appends it whenever Plan mode
          # starts) and it is the fragile one: its schema requires a per-question
          # `id`, and it registers no `prepareArguments`. ask_user_question has
          # no `id` field and ships `prepareQuestionArguments`, which undoes the
          # double-encoded `questions` array that Qwen-class models emit
          # (normalize-params.ts, upstream #244) - exactly the failure that makes
          # plan_mode_question burn two turns before succeeding on qwen3.5-9b.
          #
          # Permitted here because classifyPlanModeTool (tool-policy.ts:128-133)
          # returns "user-opt-in" for any non-builtin, so naming it is the
          # opt-in. Its only effect is putting a questionnaire in front of the
          # user, so the stricter bar applied to the lean-ctx entries below -
          # exclude anything that writes at all - does not apply.
          #
          # Caveat: Plan mode's hardcoded prompt still names plan_mode_question,
          # and `/plan finalize` retries specifically demand plan_mode_question
          # or plan_mode_complete (finalization-request.ts:4), so this does not
          # satisfy a pending finalization request.
          "ask_user_question"

          # Registered by the extension itself, shelling out to the lean-ctx
          # CLI. Invisible to an MCP tools/list probe, but real.
          "ctx_read"
          "ctx_grep"
          "ctx_find"
          "ctx_ls"

          # Bridged from the engine. Search, navigation and structure.
          "ctx_search"
          "ctx_glob"
          "ctx_tree"
          "ctx_overview"
          "ctx_callgraph"
          "ctx_graph"

          # Context assembly. ctx_compose carries no readOnlyHint because it
          # calls record_access(), but that mutates session co-access state
          # only, never the repo - and it is the primary orientation tool, so
          # excluding it would gut plan mode.
          "ctx_compose"
          "ctx_explore"
          "ctx_expand"
          "ctx_delta"

          # Reads that leave the working tree without touching the repo.
          "ctx_url_read"

          # The shell substitute. pi exposes it as `shell`; `ctx_shell` is the
          # same handler under the extension's own name. Note that plan mode's
          # safe-command filter keys off the tool *name* and covers `bash` and
          # `powershell` only - `shell` runs unfiltered here and is gated by
          # pi-permission-system's bash rules instead, via the shellTools
          # mapping above.
          "shell"
          # Inert while `replace` mode suppresses it. Named so that softening
          # pi-lean-ctx to `additive` restores the filtered bash rather than
          # silently leaving `shell` as the only shell.
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
