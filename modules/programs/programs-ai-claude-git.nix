{ ... }:
{
  # Git safety as one aspect: the rules an agent reads, the hook that enforces
  # the one rule prose never enforced on its own, and the skill that walks the
  # procedure. Split out of programs-ai-claude.nix rather than added to it
  # because all three are the same concern and none of them are generic.
  flake.modules.homeManager.programs-ai-claude-git =
    { pkgs, ... }:
    let
      # github.com/rhysyngsun/agent-skills, pinned by nvfetcher. `readFile`
      # rather than the path - see the longer note in programs-ai-claude.nix
      # for why a store-path string would be written out as the rule's body.
      ruleFile =
        name: builtins.readFile "${pkgs.localSources.rhysyngsun-agent-skills.src}/rules/${name}.md";

      # Deny-only, exactly like `searchGuard` in programs-ai-lean-ctx.nix and
      # for the same reason: a PreToolUse `allow` is a full bypass of the
      # permission system, so a guard that can only emit `deny` can subtract
      # from what is permitted and never add to it. Every gate in
      # programs-ai-claude.nix still applies on top of this.
      #
      # Two distinct denials, and the second is the one that matters:
      #
      #   1. a force push with no `--force-with-lease`
      #   2. ANY force push, lease included, where the real remote tip is not
      #      an ancestor of what is being pushed
      #
      # `--force-with-lease` alone does not cover (2). It compares against the
      # local remote-tracking ref, which is stale precisely when it matters -
      # a branch last fetched before someone else pushed passes the lease check
      # and clobbers them anyway. So the check here asks the remote
      # (`git ls-remote`) rather than trusting refs/remotes.
      #
      # Fails open everywhere: bad payload, unparseable command, missing
      # upstream, non-zero git exit and network timeout all exit 0 with no
      # output, handing the call back to the normal permission flow.
      # `CLAUDE_FORCE_PUSH_GUARD_OFF=1` disables it outright.
      forcePushGuard =
        pkgs.writers.writePython3Bin "claude-force-push-guard"
          {
            flakeIgnore = [
              "E501" # deny reasons are single long lines
            ];
          }
          ''
            import json
            import os
            import re
            import shlex
            import subprocess
            import sys

            GIT = "${pkgs.git}/bin/git"

            SPLIT_OPS = re.compile(r"\|\||&&|[|;&\n]")
            ENV_ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")

            # git global options whose value is a SEPARATE token, so the token
            # after them is never the subcommand.
            GIT_GLOBAL_WITH_VALUE = {"-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--config-env"}

            # `git push` options whose value is a separate token.
            PUSH_WITH_VALUE = {"-o", "--push-option", "--repo", "--receive-pack", "--exec", "--signed"}

            # Refspec-expanding flags. The ancestor check cannot be reduced to a
            # single src/dst pair under these, so it is skipped - the
            # no-lease denial above still applies.
            PUSH_BULK = {"--all", "--mirror", "--tags", "--prune"}

            TIMEOUT = 10


            def silent():
                sys.exit(0)


            def deny(reason):
                json.dump(
                    {
                        "hookSpecificOutput": {
                            "hookEventName": "PreToolUse",
                            "permissionDecision": "deny",
                            "permissionDecisionReason": reason,
                        }
                    },
                    sys.stdout,
                )
                sys.exit(0)


            def git(cwd, *args, check=True):
                try:
                    proc = subprocess.run(
                        [GIT, "-C", cwd, *args],
                        capture_output=True,
                        text=True,
                        timeout=TIMEOUT,
                    )
                except Exception:
                    return None
                if check and proc.returncode != 0:
                    return None
                return proc


            def push_segments(command):
                """Every `git push ...` argv in the command line, not just the first.

                searchGuard looks at the leading token only, which is right for
                `ls | grep foo`. It is wrong here: a force push habitually
                trails an `&&`.
                """
                out = []
                for part in SPLIT_OPS.split(command):
                    try:
                        toks = shlex.split(part)
                    except ValueError:
                        continue
                    i = 0
                    while i < len(toks) and ENV_ASSIGN.match(toks[i]):
                        i += 1
                    if i >= len(toks) or os.path.basename(toks[i]) != "git":
                        continue
                    i += 1
                    while i < len(toks) and toks[i].startswith("-"):
                        if toks[i] in GIT_GLOBAL_WITH_VALUE:
                            i += 2
                        else:
                            i += 1
                    if i < len(toks) and toks[i] == "push":
                        out.append(toks[i + 1:])
                return out


            def classify(args):
                """(forced, leased, dry_run, positionals, bulk) for one push argv."""
                forced = leased = dry_run = bulk = False
                positionals = []
                i = 0
                while i < len(args):
                    a = args[i]
                    if a == "--":
                        positionals.extend(args[i + 1:])
                        break
                    if a.startswith("--"):
                        name = a.split("=", 1)[0]
                        if name in ("--force-with-lease", "--force-if-includes"):
                            leased = True
                        elif name == "--force":
                            forced = True
                        elif name == "--dry-run":
                            dry_run = True
                        elif name in PUSH_BULK:
                            bulk = True
                        if name in PUSH_WITH_VALUE and "=" not in a:
                            i += 2
                            continue
                    elif a.startswith("-") and len(a) > 1:
                        # Short flags bundle: `git push -fu origin main`.
                        if "f" in a[1:]:
                            forced = True
                        if "n" in a[1:]:
                            dry_run = True
                        if a in PUSH_WITH_VALUE:
                            i += 2
                            continue
                    else:
                        positionals.append(a)
                    i += 1

                # A leading `+` on a refspec is a force push spelled another way.
                for p in positionals[1:]:
                    if p.startswith("+"):
                        forced = True
                return forced, leased, dry_run, positionals, bulk


            def resolve_refs(cwd, positionals):
                """(remote, src, dst) for the push, or None if it cannot be pinned down."""
                remote = positionals[0] if positionals else None
                refspec = positionals[1] if len(positionals) > 1 else None

                if remote is None:
                    proc = git(cwd, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
                    if proc is None or "/" not in proc.stdout.strip():
                        return None
                    remote, upstream_branch = proc.stdout.strip().split("/", 1)
                    return remote, "HEAD", upstream_branch

                if refspec is None:
                    proc = git(cwd, "symbolic-ref", "--short", "HEAD")
                    if proc is None:
                        return None
                    branch = proc.stdout.strip()
                    return remote, "HEAD", branch

                spec = refspec.lstrip("+")
                if ":" in spec:
                    src, dst = spec.split(":", 1)
                else:
                    src = dst = spec
                if not src or not dst:
                    return None
                return remote, src, dst


            def check_stale(cwd, remote, src, dst):
                ls = git(cwd, "ls-remote", "--heads", remote, dst)
                if ls is None:
                    return  # no network, no opinion
                line = ls.stdout.strip().splitlines()
                if not line:
                    return  # branch does not exist on the remote yet
                remote_sha = line[0].split()[0]

                local = git(cwd, "rev-parse", "--verify", src + "^{commit}")
                if local is None:
                    return
                local_sha = local.stdout.strip()

                if remote_sha == local_sha:
                    return

                if git(cwd, "cat-file", "-e", remote_sha + "^{commit}") is None:
                    deny(
                        f"Blocked: {remote}/{dst} is at {remote_sha[:12]}, which is not in your object store - you have not fetched it.\n\n"
                        "Force-pushing now would discard commits you have never seen. --force-with-lease does NOT protect you here: it compares against your local refs/remotes copy, which is exactly what is stale.\n\n"
                        f"  git fetch {remote} {dst}\n"
                        f"  git log --oneline {src}..{remote}/{dst}\n\n"
                        "Then rebase onto it, or come back and tell me the remote commits are meant to go."
                    )

                if git(cwd, "merge-base", "--is-ancestor", remote_sha, local_sha) is None:
                    behind = git(cwd, "rev-list", "--count", local_sha + ".." + remote_sha)
                    n = behind.stdout.strip() if behind else "some"
                    deny(
                        f"Blocked: {remote}/{dst} has {n} commit(s) that {src} does not contain, so this push would discard them.\n\n"
                        f"  git log --oneline {src}..{remote_sha}\n\n"
                        "Rebase onto the remote tip, or stop and ask before overwriting it."
                    )


            def main():
                if os.environ.get("CLAUDE_FORCE_PUSH_GUARD_OFF"):
                    silent()

                try:
                    payload = json.loads(sys.stdin.read())
                except Exception:
                    silent()

                if payload.get("tool_name") != "Bash":
                    silent()

                command = (payload.get("tool_input") or {}).get("command") or ""
                cwd = payload.get("cwd") or os.getcwd()

                for args in push_segments(command):
                    forced, leased, dry_run, positionals, bulk = classify(args)
                    if dry_run or not (forced or leased):
                        continue
                    if forced and not leased:
                        deny(
                            "Blocked: force-push without --force-with-lease.\n\n"
                            "A plain --force overwrites the remote branch whatever state it is in. --force-with-lease refuses when the remote moved since your last fetch.\n\n"
                            "  git fetch <remote> <branch>\n"
                            "  git log --oneline <branch>..<remote>/<branch>    # empty means safe\n"
                            "  git push --force-with-lease <remote> <branch>\n\n"
                            "Snapshot the tip first (git rev-parse <branch>) so an undo is one git reset --hard."
                        )
                    if bulk:
                        continue
                    refs = resolve_refs(cwd, positionals)
                    if refs is None:
                        continue
                    check_stale(cwd, *refs)

                silent()


            main()
          '';
    in
    {
      # ~/.claude/rules/git.md. Every bullet here is a postmortem of something
      # that actually happened on this machine: a stale local branch
      # force-pushed over a correct remote, and an eight-PR stack whose
      # ancestor chain was severed by replaying each child off the original
      # base instead of onto its rebased parent.
      #
      # The force-with-lease bullet is backed by the hook above, so it states
      # the fact rather than asking. The rest are procedure, which prose is
      # the right place for.
      programs.claude-code.rules.git = ruleFile "git";

      # `settings.hooks` lists concatenate across home-manager modules, so this
      # sits alongside the two lean-ctx PreToolUse entries rather than
      # replacing them. Both guards will run against a Bash call; both are
      # deny-only, so the order between them does not matter.
      programs.claude-code.settings.hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${forcePushGuard}/bin/claude-force-push-guard";
              # The guard's own subprocess timeout is 10s and it fails open, so
              # this bound never decides an outcome. It is generous because
              # `git ls-remote` is a network round trip.
              timeout = 20;
            }
          ];
        }
      ];

      # The third leg of this aspect, the `stacked-prs` skill, is in
      # github.com/rhysyngsun/agent-skills and reaches ~/.claude/skills/
      # through the discovery walk in programs-ai-claude-personal.nix.
      #
      # Half of it could go upstream and half could not. The `--onto`
      # procedure and the ancestor-chain check are portable and belong in
      # agent-kit/skills/process/ once they have earned their keep. The
      # `gh stack` half is machine-local: the extension is installed ad-hoc
      # with `gh extension install github/gh-stack` and is declared nowhere in
      # this flake, which is why the skill probes for it rather than assuming
      # it.
    };
}
