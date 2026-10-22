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
    in
    {
      home.packages = [ pkgs.lean-ctx ];

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
