{ ... }:
{
  # lean-ctx's engine and its IPC daemon. Shared rather than pi-specific: the
  # same binary backs Claude Code's `mcpServers.lean-ctx` (programs-ai-claude.nix,
  # programs-ai-claude-mit.nix) and pi's pi-lean-ctx extension
  # (programs-ai-pi-local.nix), and all three talk to one daemon per user.
  flake.modules.homeManager.programs-ai-lean-ctx =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      # `dirs::data_local_dir()/lean-ctx` in lean-ctx terms - the socket, the pid
      # file and the stderr log all live here, and the path is not independently
      # configurable (ipc/unix.rs hardcodes `data_dir().join("daemon.sock")`).
      dataDir = "${config.xdg.dataHome}/lean-ctx";

      # Retire a daemon that a client autostarted while this unit was down.
      #
      # Deliberately NOT `lean-ctx daemon stop`: every CLI stop path
      # (`daemon stop`, `daemon restart`, `serve --stop`, `lean-ctx stop`) calls
      # `daemon_autostart::stop()` first, which shells out to
      # `systemctl --user stop lean-ctx-daemon` - i.e. it would ask systemd to
      # stop the very unit invoking it, killing this script mid-flight and
      # leaving the unit cleanly "inactive (dead)" that `Restart=on-failure`
      # will not retry.
      #
      # Matched by process rather than by pid file: a daemon whose socket was
      # already stolen once is live with no pid file at all, which is precisely
      # the state this guards against. ExecStart has not been launched yet, so
      # any `--_foreground-daemon` process owned by us here is a stray. SIGINT
      # rather than SIGTERM because that is what lean-ctx's graceful shutdown
      # listens for - it unlinks its own socket and pid file on the way out.
      # Both units shell out: `git` (graph_enricher, ctx_impact, ctx_pack),
      # `ps`/`pgrep` (ipc/process), and `nice` + `ionice` (setup/index_build,
      # which spawns `nice -n 19 ionice -c 3 lean-ctx index build` and silently
      # fails to spawn at all when `nice` is absent). The daemon additionally
      # runs agent-authored commands through ctx_shell. Autostarted by an agent
      # either would inherit a full interactive PATH; under systemd they get the
      # bare user-manager one, so resemble the login PATH and keep an explicit
      # floor under it. The shell itself needs no entry - `find_real_shell`
      # probes absolute /bin/zsh, /bin/bash, /bin/sh.
      runtimePath = "PATH=${
        lib.concatStringsSep ":" [
          "/run/wrappers/bin"
          "${config.home.profileDirectory}/bin"
          "/run/current-system/sw/bin"
          (lib.makeBinPath (
            with pkgs;
            [
              git
              coreutils
              util-linux
              procps
            ]
          ))
        ]
      }";

      stopStray = pkgs.writeShellScript "lean-ctx-daemon-stop-stray" ''
        set -u

        # The authoritative test is the resolved executable, not a `pgrep -f`
        # argv match: that matches a substring anywhere in any command line, so
        # any shell merely mentioning the flag is a false positive (this bit
        # once, during testing). /proc/<pid>/exe cannot be spoofed that way, and
        # readlink failing on another user's process is the uid scoping.
        #
        # `comm` is a fork-free pre-filter - bash reads it with a builtin - so
        # this does not fork a readlink per process on the machine. It is
        # truncated to 15 chars (".lean-ctx-wrapp" for the wrapper), hence only
        # ever a filter, never the decision.
        is_foreground_daemon() {
          local pid=$1 comm exe arg cmd=""

          # `2>/dev/null` precedes each input redirect on purpose: redirections
          # are processed left to right, so trailing it would not suppress
          # bash's own "No such file" when a process exits mid-scan - a race
          # this hits routinely, because a client-spawned daemon's pid file can
          # name a short-lived intermediate from its detached double-fork.

          read -r comm 2>/dev/null < "/proc/$pid/comm" || return 1
          case "$comm" in
            *lean-ctx*) ;;
            *) return 1 ;;
          esac

          exe=$(readlink "/proc/$pid/exe" 2>/dev/null) || return 1
          case "$exe" in
            *lean-ctx*) ;;
            *) return 1 ;;
          esac

          while IFS= read -r -d "" arg; do
            cmd="$cmd $arg"
          done 2>/dev/null < "/proc/$pid/cmdline" || return 1
          case "$cmd" in
            *--_foreground-daemon*) return 0 ;;
            *) return 1 ;;
          esac
        }

        strays() {
          local d pid
          for d in /proc/[0-9]*; do
            pid=''${d#/proc/}
            if is_foreground_daemon "$pid"; then
              printf '%s\n' "$pid"
            fi
          done
        }

        found=$(strays)
        if [ -n "$found" ]; then
          for pid in $found; do
            kill -INT "$pid" 2>/dev/null || true
          done

          n=0
          while [ -n "$(strays)" ] && [ "$n" -lt 25 ]; do
            sleep 0.2
            n=$((n + 1))
          done

          for pid in $(strays); do
            kill -KILL "$pid" 2>/dev/null || true
          done
        fi

        # A SIGKILLed stray leaves both behind. lean-ctx self-heals a stale pid
        # file, but not when we are about to bind the socket it names.
        rm -f ${lib.escapeShellArg "${dataDir}/daemon.pid"}
        exit 0
      '';

      # Claude Code will not reach for a deferred tool on its own. Every MCP tool
      # schema sits behind a `ToolSearch` round trip while `Grep`, `Glob` and the
      # pre-approved `Bash(rg:*)`/`Bash(grep:*)` cost nothing, so the model always
      # takes the free path - zero ctx_* calls against thousands of Bash ones.
      #
      # Deferral is NOT tool-count driven. Measured: with lean-ctx as the *only*
      # MCP server (18 tools, 51 total) ctx_* were still deferred. The only switch
      # is `ENABLE_TOOL_SEARCH=false`, which inlines every MCP schema and takes the
      # prompt from 47k to 287.6k - rejected as too expensive. See the comment in
      # programs-ai-claude.nix for the full measurement table.
      #
      # So the incentive is corrected from the other side: deny in-project code
      # search and tell the model how to redo it through lean-ctx.
      #
      # CRITICAL CONTRAST with upstream's `lean-ctx hook rewrite`, refused below:
      # this script only ever emits `deny`, never `allow`. A PreToolUse `allow` is
      # a full bypass of the permission system, which is why the upstream hook -
      # answering `allow` to `git push`, `rm -rf`, everything - cannot be used. A
      # deny-only guard subtracts from what is permitted and can never add to it,
      # so every gate in programs-ai-claude.nix still applies, including the
      # guardrails rule about confirming before a commit or a push.
      #
      # Fails open everywhere: bad payload, missing daemon, unreadable index,
      # subprocess timeout and unknown tool all exit 0 silently, which hands the
      # call back to the normal permission flow rather than blocking it.
      searchGuard =
        pkgs.writers.writePython3Bin "lean-ctx-search-guard"
          {
            flakeIgnore = [
              "E501" # the deny reason and the selector are single long lines
            ];
          }
          ''
            import json
            import os
            import re
            import shlex
            import subprocess
            import sys

            LEAN_CTX = "${pkgs.lean-ctx}/bin/lean-ctx"

            # `find` earns its place: `find . -name '*.nix'` is a ctx_glob in disguise.
            SEARCH_BINS = {
                "rg", "grep", "egrep", "fgrep", "ag", "ack", "ack-grep",
                "fd", "fdfind", "find",
            }

            BYPASS = "lean-ctx:bypass"

            SELECTOR = (
                "ToolSearch(query=\"select:"
                "mcp__plugin_claude-code-home-manager_lean-ctx__ctx_compose,"
                "mcp__plugin_claude-code-home-manager_lean-ctx__ctx_search,"
                "mcp__plugin_claude-code-home-manager_lean-ctx__ctx_glob,"
                "mcp__plugin_claude-code-home-manager_lean-ctx__ctx_read\")"
            )

            REASON = (
                "Blocked: this project is lean-ctx-indexed, so route code search through it.\n\n"
                "Load the tools once (they are deferred, so this round trip is required):\n"
                f"{SELECTOR}\n\n"
                "Then:\n"
                "  - content search -> ctx_search(action=\"regex\", pattern=..., path=...)\n"
                "  - files by glob  -> ctx_glob(pattern=...)\n"
                "  - orienting in unfamiliar code -> ctx_compose(task=...) first\n\n"
                "You get ranked, compressed matches with enclosing-symbol annotations, and "
                "credential files are skipped by boundary policy rather than read.\n\n"
                "Genuinely need raw search - a binary file, a non-indexed corpus, a regex "
                f"ctx_search cannot express? Append ' # {BYPASS}' to the shell command "
                "and it runs (still subject to the normal Bash permission rules)."
            )

            ENV_ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
            SPLIT_OPS = re.compile(r"\|\||&&|[|;&\n]")


            def silent():
                sys.exit(0)


            def deny():
                json.dump(
                    {
                        "hookSpecificOutput": {
                            "hookEventName": "PreToolUse",
                            "permissionDecision": "deny",
                            "permissionDecisionReason": REASON,
                        }
                    },
                    sys.stdout,
                )
                sys.exit(0)


            def git_root(path):
                p = os.path.abspath(path)
                if not os.path.isdir(p):
                    p = os.path.dirname(p)
                while True:
                    if os.path.exists(os.path.join(p, ".git")):
                        return p
                    parent = os.path.dirname(p)
                    if parent == p:
                        return None
                    p = parent


            def indexed(root):
                # ~10ms, and deliberately daemon-independent: `index status` reads
                # the on-disk index, so a stopped lean-ctx-daemon.service does not
                # make this lie. That matters because the MCP servers Claude Code
                # spawns autostart their own daemon anyway - the unit being down
                # does not mean ctx_search is unavailable, so it must not suppress
                # the guard. A non-zero exit or a timeout means "no opinion".
                try:
                    proc = subprocess.run(
                        [LEAN_CTX, "index", "status", "--root", root],
                        capture_output=True,
                        text=True,
                        timeout=3,
                    )
                except Exception:
                    return False
                for line in proc.stdout.splitlines():
                    if "BM25 Index:" in line and "ready" in line:
                        return True
                return False


            def leading_command(command):
                # Only the FIRST command counts. `ls | grep foo` filters command output
                # and is not code search; `git grep` and `nix search` are not our
                # binaries either, and both are caught by comparing the leading token.
                head = SPLIT_OPS.split(command, 1)[0]
                try:
                    toks = shlex.split(head)
                except ValueError:
                    return None, []
                i = 0
                while i < len(toks) and ENV_ASSIGN.match(toks[i]):
                    i += 1
                if i >= len(toks):
                    return None, []
                return os.path.basename(toks[i]), toks[i + 1:]


            def path_args(args, cwd):
                out = []
                for a in args:
                    if a.startswith("-"):
                        continue
                    cand = a if os.path.isabs(a) else os.path.join(cwd, a)
                    if os.path.exists(cand):
                        out.append(os.path.abspath(cand))
                return out


            def main():
                if os.environ.get("LEAN_CTX_GUARD_OFF"):
                    silent()

                try:
                    payload = json.loads(sys.stdin.read())
                except Exception:
                    silent()

                tool = payload.get("tool_name") or ""
                tool_input = payload.get("tool_input") or {}
                cwd = payload.get("cwd") or os.getcwd()

                if tool in ("Grep", "Glob"):
                    target = tool_input.get("path") or cwd
                    if not os.path.isabs(target):
                        target = os.path.join(cwd, target)
                    targets = [target]
                elif tool == "Bash":
                    command = tool_input.get("command") or ""
                    if BYPASS in command:
                        silent()
                    binname, args = leading_command(command)
                    if binname not in SEARCH_BINS:
                        silent()
                    # No path argument means the search runs against the cwd.
                    targets = path_args(args, cwd) or [cwd]
                else:
                    silent()

                for target in targets:
                    root = git_root(target)
                    if root is not None and indexed(root):
                        deny()
                silent()


            main()
          '';

    in
    {
      home.packages = [ pkgs.lean-ctx ];

      # Replaces the SKILL.md `lean-ctx setup` wrote imperatively into
      # ~/.claude/skills/lean-ctx/ (0600, outside the store, survives a switch).
      # Upstream's copy told the agent to load the tools with
      # `select:mcp__lean-ctx__ctx_compose,…`, which matches nothing here - the real
      # prefix carries the plugin name, `mcp__plugin_claude-code-home-manager_lean-ctx__`
      # - so following the skill returned zero tools and the agent fell back to Bash.
      # That one wrong prefix is why ctx_* was called 5 times against Bash's 12,388.
      #
      # `programs.claude-code.skills` is typed
      # `either (attrsOf (oneOf [lines path str])) path`; a string value lands at
      # .claude/skills/<name>/SKILL.md (home-manager claude-code.nix, mkSkillEntry).
      # The `either` wrapper still merges attrsets across modules, so this coexists
      # with programs-ai-claude-mit.nix defining the whole attrset from agent-kit.
      programs.claude-code.skills.lean-ctx = ''
        ---
        name: lean-ctx
        description: Pick the right lean-ctx tool for reading, searching, understanding and running code with fewer tokens and fewer round trips. Use when lean-ctx MCP tools (ctx_*) are available or when a command output, file read or search would be large.
        ---

        # lean-ctx

        lean-ctx shapes context before it reaches you: cached reads, focused search, a
        symbol index and a call graph over the current repo. Two rules beat every
        detail:

        1. **Fewer round trips beat smaller outputs.** One call that answers the
           question is cheaper than three small ones. Never add a call just to save a
           few hundred tokens.
        2. **Never wait by polling.** Do not loop `sleep` + status checks.

        ## Loading the tools

        These tools are deferred - the host lists them by name only. Load what the
        task needs in **one** call:

            ToolSearch(query="select:mcp__plugin_claude-code-home-manager_lean-ctx__ctx_compose,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_search,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_read,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_callgraph")

        The prefix is `mcp__plugin_claude-code-home-manager_lean-ctx__`. A bare
        `mcp__lean-ctx__...` selector matches nothing.

        ## Start here - no built-in equivalent

        | You want to... | Call |
        |---|---|
        | Understand how something works (unknown location) | `ctx_compose(task)` - ranked files + inline source in one call; use it FIRST instead of search -> read -> read |
        | Find the exact definition of a symbol | `ctx_search(action="symbol", name=...)` |
        | Find code by meaning | `ctx_search(action="semantic", query=...)` |
        | Who calls X / what X calls | `ctx_callgraph(action="callers"\|"callees", symbol=...)` |
        | A file's shape without its body | `ctx_read(path, mode="signatures"\|"map")` |

        These four are the reason to reach for lean-ctx at all. Everything below
        overlaps a built-in and is a judgement call.

        ## Overlaps a built-in

        | You want to... | Call |
        |---|---|
        | Find a text/regex pattern | `ctx_search(pattern=..., path=...)`, or `Bash(rg ...)` for a known path |
        | Read a file you will edit | `ctx_read(path, mode="anchored")`, then the native `Edit` tool |
        | Read a range | `ctx_read(path, mode="lines:N-M")` |
        | Re-check a file after editing | `ctx_read(path, mode="diff")` |
        | List files / directory shape | `ctx_glob(pattern)` / `ctx_tree(path, depth)` |
        | Remember across sessions | `ctx_session(action="finding"\|"decision"\|"task", value=...)`; durable project facts: `ctx_knowledge(action="remember", ...)` |

        **Do not use `ctx_shell`.** Run commands with the native `Bash` tool. The
        lean-ctx server is allowed whole-server here, so `ctx_shell` would bypass the
        per-command `Bash(...)` permission gates - including the ones requiring
        confirmation before a commit or a push. This deliberately contradicts the
        server's own "Shell/bash -> ctx_shell" instruction.

        Also do not read or search *through* a shell (`cat`, `sed -n`, `grep`): that
        bypasses the read cache and the symbol index. Use `ctx_read` / `ctx_search`.

        ## Tools not in the list

        The exposed surface is the `standard` profile (~19 tools). A tool named above
        that your list lacks is still callable:

            ctx_call(name="ctx_knowledge", arguments={...})
            ctx_call(name="ctx_discover_tools", arguments={"query": "..."})

        ## Long-running commands

        - Prefer the host's own background execution that notifies on completion:
          `Bash` with `run_in_background`, or `Monitor`. Start it, then continue other
          work or end the turn - you will be told when it finishes.
        - Never `sleep` in a loop to poll for a result.

        ## Truncated output

        Compressed or archived output ends with a recovery handle. Fetch only the
        slice you need - `ctx_expand(id, search=... | head=N | json_path=...)`, or
        `ctx_read(path, raw=true)` for exact bytes. Do not re-run the command.

        ## Configuration

        This install is declarative, in `modules/programs/programs-ai-lean-ctx.nix` of
        the nixos flake. Do **not** run `lean-ctx setup`, `lean-ctx bootstrap`,
        `lean-ctx config set`, or any `curl | bash` installer: the config and this file
        are read-only store symlinks, so those commands fail - and where they succeed
        they leave untracked drift. Change the nix module and run `just switch-user`.
      '';

      # The deny-only guard defined in the `let` above. `matcher` is a regex over
      # the tool name, and Bash is in it on purpose: gating only Grep/Glob would
      # push the model straight to `Bash(rg:*)`, which programs-ai-claude.nix
      # pre-approves - the exact substitution that produced thousands of Bash
      # calls and almost no ctx_* ones. The script narrows Bash itself, firing
      # only when the *leading* token is a search binary aimed at an indexed
      # project, so `git grep`, `nix search` and `... | grep` are untouched.
      #
      # `settings.hooks` lists concatenate across home-manager modules, so this
      # coexists with the witan entries in programs-ai-claude-mit.nix rather than
      # replacing them. PreToolUse had no other registrations when this landed.
      programs.claude-code.settings.hooks.PreToolUse = [
        {
          matcher = "Grep|Glob|Bash";
          hooks = [
            {
              type = "command";
              command = "${searchGuard}/bin/lean-ctx-search-guard";
              # Generous against a cold daemon; the script's own subprocess
              # timeout is 3s and it fails open, so this bound is never the
              # thing that decides an outcome.
              timeout = 10;
            }
          ];
        }
      ];

      # Previously unmanaged: `lean-ctx setup` wrote this file (0600) and, because
      # ~/.claude/settings.json is a read-only store symlink it could not patch, left
      # four orphaned PreToolUse scripts in ~/.claude/hooks/ that nothing invokes.
      # `[setup] manage_hooks`/`auto_update_mcp` are the knobs that did that, so they
      # are off here and the read-only symlink is the belt to that braces.
      #
      # Deliberately NOT registering lean-ctx's own `hook rewrite` as a PreToolUse
      # hook, which is what those orphans were for: fed a real payload it answers
      # `permissionDecision: "allow"` for *everything* - `git push`, `git commit`,
      # `sudo nixos-rebuild switch`, `rm -rf` - and in Claude Code that is a full
      # bypass of the permission system, voiding the guardrails rule about confirming
      # before a commit or a push. Our own `searchGuard` above is the sanctioned
      # alternative and is not a contradiction of this: it emits `deny` and never
      # `allow`, so it can only ever subtract from what is permitted.
      #
      # Side effect to live with: `lean-ctx setup`, `bootstrap`, `config set`,
      # `tools <profile>` and `doctor --fix` can no longer write their config. That is
      # the trade - this file is edited here now. The daemon itself only reads it.
      #
      # `tool_profile` must agree with LEAN_CTX_TOOL_PROFILE in
      # programs-ai-claude.nix: the file used to say "power" (79 tools) while the env
      # var held Claude's surface at "standard" (17), so `lean-ctx tools show`
      # reported a profile no agent was actually seeing.
      #
      # Telemetry ships `enabled = true, preference = "default_on"` and was actively
      # sending (`lean-ctx telemetry status` reported "Sending: active", last sent the
      # day this was written). `enabled = false` alone stops it; the preference is
      # pinned alongside so an upgrade that re-reads consent cannot treat the absence
      # of an explicit choice as "default_on" again.
      #
      # Mind the enum. `preference` accepts only `default_on`, `explicitly_enabled`
      # and `explicitly_disabled` - the obvious `"off"` does not parse, and the
      # failure mode is silent-but-total: lean-ctx answers "refusing invalid global
      # config.toml" and falls back to built-in defaults for *everything*, so one typo
      # here quietly reverts `tool_profile` and both `[setup]` keys too. Verify any
      # edit against a scratch copy rather than the live file:
      #
      #   d=$(mktemp -d); mkdir -p "$d/lean-ctx"
      #   cp ~/.config/lean-ctx/config.toml "$d/lean-ctx/"   # then edit the copy
      #   XDG_CONFIG_HOME="$d" lean-ctx tools show
      #
      # `tools show` names where the profile came from, so a line reading
      # `config.toml (tool_profile = "standard")` is proof the file was accepted;
      # `default` means it was rejected.
      xdg.configFile."lean-ctx/config.toml".text = ''
        minimal_overhead = true
        structure_first = true
        journal_enabled = true
        auto_capture = true
        compression_level = "standard"
        tool_profile = "standard"
        shell_allowlist_extra = [ "prek" ]
        behavior_nudges = "auto"

        # preference is an enum: only default_on | explicitly_enabled |
        # explicitly_disabled. A bad value voids this whole file - see the nix module.
        [telemetry]
        enabled = false
        preference = "explicitly_disabled"

        [setup]
        auto_update_mcp = false
        manage_hooks = false

        [gain]
        auto_publish = false
      '';

      systemd.user.services.lean-ctx-daemon = {
        Unit = {
          Description = "lean-ctx IPC daemon";
          After = [ "network.target" ];
          # Upstream's own rate limit (daemon_autostart.rs install_systemd).
          StartLimitIntervalSec = 300;
          StartLimitBurst = 5;
        };

        Service = {
          Type = "simple";

          # Load-bearing, not hygiene. `bind_listener` (ipc/unix.rs) unlinks an
          # existing socket path unconditionally, without probing for a live
          # listener - so coming up while a client-autostarted daemon holds the
          # socket does not fail, it silently steals it and leaves that process
          # orphaned. See the script for why this is not the lean-ctx CLI.
          ExecStartPre = "${stopStray}";

          # `--_foreground-daemon` *is* the daemon. `serve --daemon` double-forks
          # and detaches, which a Type=simple unit must never get. The flag is
          # UDS-only - --host/--port parse into the config but are never bound on
          # this path (cli/dispatch/network).
          ExecStart = "${pkgs.lean-ctx}/bin/lean-ctx serve --_foreground-daemon";

          # Load-bearing twice over. The graceful-shutdown future is wired to
          # `tokio::signal::ctrl_c` only, so the default SIGTERM has no handler:
          # it would kill the daemon mid-request AND skip
          # `cleanup_daemon_files()`, which is what unlinks the socket and the
          # pid file. The daemon maintains that pid file itself
          # (`init_foreground_daemon` -> `write_pid_file`), so nothing here
          # needs to write it - but SIGINT is what lets it clean up.
          KillSignal = "SIGINT";

          Restart = "on-failure";
          RestartSec = 5;

          # Deliberately neutral, replacing the cwd the daemon used to inherit
          # from whichever agent first autostarted it. `$HOME` is explicitly
          # refused as a scan root (core/graph_index), so this cannot trigger a
          # home-wide index - clients pass their own project roots per call. One
          # "cannot index home directory" warning at startup is expected.
          WorkingDirectory = config.home.homeDirectory;

          Environment = [
            "RUST_LOG=info"
            runtimePath
          ];
        };

        # Not a graphical-session unit, unlike the eww/swww/mpvpaper services in
        # this repo: nothing here touches Wayland, and an SSH session wants the
        # daemon too.
        Install.WantedBy = [ "default.target" ];
      };

      # The read-only web UI over the same data, on http://localhost:3333.
      systemd.user.services.lean-ctx-dashboard = {
        Unit = {
          Description = "lean-ctx dashboard";
          # Ordering only, deliberately not Requires=: the dashboard reads the
          # stats and session files directly and does its own graph analysis -
          # it touches the daemon only through `is_daemon_running()` for its
          # health card (dashboard/routes/health.rs). So it will never autostart
          # a competing daemon; After= just keeps that card from being briefly
          # wrong at login.
          After = [
            "network.target"
            "lean-ctx-daemon.service"
          ];
          StartLimitIntervalSec = 300;
          StartLimitBurst = 5;
        };

        Service = {
          Type = "simple";

          # --open=none: without it the dashboard tries to launch a browser,
          # which is meaningless from a service and is the one thing that makes
          # it non-idempotent at login.
          #
          # --no-auth: the default mints a *random* bearer token per start, so a
          # bookmarked URL breaks on every restart - unusable for a long-lived
          # unit. Per lean-ctx's own help this is not "unprotected": CSRF and
          # DNS-rebinding stay blocked by Sec-Fetch-Site/Origin/Host checks, and
          # --host pins the bind to loopback regardless.
          ExecStart = lib.concatStringsSep " " [
            "${pkgs.lean-ctx}/bin/lean-ctx dashboard"
            "--port=3333"
            "--host=127.0.0.1"
            "--no-auth"
            "--open=none"
          ];

          # No KillSignal override here, unlike the daemon: the dashboard has no
          # ctrl_c handler and no socket or pid file to unlink, so plain SIGTERM
          # is correct.
          Restart = "on-failure";
          RestartSec = 5;

          # Load-bearing, not tidiness. The deep views resolve exactly one
          # project via `detect_project_root_for_dashboard`
          # (dashboard/routes/helpers.rs): --project= -> LEAN_CTX_PROJECT_ROOT ->
          # cwd-scoped session -> the global latest-pointer, "the most recently
          # active session across all projects". Starting from a neutral $HOME
          # is what skips the cwd rungs and lands on that pointer, so the
          # dashboard follows whichever repo is currently being worked in
          # instead of being pinned to wherever it happened to start. The
          # cross-project "Connected workspaces" panel is unaffected - it is
          # built from session history and always covers every project.
          WorkingDirectory = config.home.homeDirectory;

          Environment = [
            "RUST_LOG=info"
            runtimePath
          ];
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
}
