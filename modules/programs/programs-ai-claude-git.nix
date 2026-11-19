{ ... }:
{
  # Git safety as one aspect: the rules an agent reads, the hook that enforces
  # the one rule prose never enforced on its own, and the skill that walks the
  # procedure. Split out of programs-ai-claude.nix rather than added to it
  # because all three are the same concern and none of them are generic.
  flake.modules.homeManager.programs-ai-claude-git =
    { pkgs, ... }:
    let
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
      programs.claude-code.rules.git = ''
        # Git and stacked PRs

        - Never force-push without first comparing against the remote. `git fetch
          <remote> <branch>`, then `git log --oneline <branch>..<remote>/<branch>`
          (what you would destroy) and the reverse (what you would add). If the
          first is non-empty, stop and ask.
        - Force-push only with `--force-with-lease`. A plain `--force`/`-f` is
          blocked by a hook, as is a lease push where the remote has moved.
        - Snapshot what you are about to move before any rebase or force-push:
          `git rev-parse <branch>` for each branch in the stack. Recovery is then
          one `git reset --hard <sha>` instead of a reconstruction.
        - Rebase a stack parent-first, one child at a time, onto its *rebased*
          parent:

              git rebase --onto <new-parent> <old-parent> <child>

          Replaying each child off the original base is what severs the ancestor
          chain - every branch rebases cleanly and the stack is still wrong.
        - After the whole pass, verify the chain before pushing anything:
          `git log --oneline --graph <branch1> <branch2> ...`. Each branch must
          contain its parent.
        - When a parent merges, retarget the child PR with `gh pr edit --base`.

        # Before you push

        Before pushing a branch that opens or updates a pull request, run the
        `code-review` skill against the diff and tell me what it found. Every time
        an independent reviewer has looked at a diff here it has found something -
        a no-op hook, a stale editable install, an automerge regression - and the
        misses all came from self-assessing with full context, where you see what
        you meant rather than what you wrote.
      '';

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

      # A string value lands at .claude/skills/restack/SKILL.md - see the
      # comment at programs-ai-lean-ctx.nix:412 for why an inline skill
      # coexists with the agent-kit attrset discovered in
      # programs-ai-claude-mit.nix.
      #
      # This is the one local skill that arguably belongs upstream: every other
      # process skill lives in mitodl/agent-kit and arrives by repin. It is here
      # because the rebase procedure it encodes was learned on this machine. Move
      # it to agent-kit/skills/process/ when it has earned its keep.
      programs.claude-code.skills.restack = ''
        ---
        name: restack
        description: Rebase a stack of pull requests onto a moved base safely - snapshot the tips, rebase parent-first with --onto, verify the ancestor chain, then push with --force-with-lease. Use when a parent PR merged, when main moved under a stack, when asked to "restack", "rebase the stack", "rebase my PRs onto main", or after addressing feedback on a branch that has children.
        ---

        # restack

        A stack is a chain of branches where each one's base is the previous one.
        Rebasing it wrong is the single most expensive recoverable mistake in this
        workflow, and it fails silently: every branch rebases cleanly and the stack
        is still broken.

        **The failure mode.** Replaying each child onto the new base independently
        gives you N branches that all contain the base and none of which contain
        their parent. `git rebase <new-base> <child>` is the wrong command. The
        right one names the old parent explicitly, so only the child's own commits
        move:

            git rebase --onto <rebased-parent> <old-parent> <child>

        ## 1. Establish the stack

            git fetch origin --prune
            gh pr list --author @me --state open --json number,headRefName,baseRefName,title

        Order the branches bottom-up by following `baseRefName` from the branch
        whose base is the trunk. Print the chain and the PR number for each before
        touching anything. If `gh pr list` does not cover the whole stack - a
        branch with no PR yet - get the rest from the user rather than guessing.

        ## 2. Snapshot before moving anything

            for b in <branches>; do echo "$b $(git rev-parse "$b")"; done

        Keep that output in the transcript. It is the undo: `git reset --hard <sha>`
        per branch restores the pre-rebase state exactly.

        ## 3. Rebase bottom-up

        Record each branch's old tip *before* you rebase it, because it becomes the
        `<old-parent>` for its child:

            old_parent=$(git rev-parse <parent>)       # BEFORE rebasing <parent>
            git rebase --onto origin/main $(git merge-base <parent> origin/main) <parent>
            # then, for each child in order:
            git rebase --onto <parent> "$old_parent" <child>

        Stop on the first conflict and resolve it. Do not continue down the stack
        with an unresolved branch behind you.

        ## 4. Verify the chain - do not skip this

            git log --oneline --graph --decorate <branch1> <branch2> <branch3> ...

        Every branch must contain its parent. Check it explicitly:

            git merge-base --is-ancestor <parent> <child> && echo "ok: <child>"

        Run that for every parent/child pair. A silent `ok` for all of them is the
        only evidence the stack survived.

        ## 5. Stop and show the user

        Print the graph and the per-pair ancestor results and **wait for
        confirmation**. Nothing has been pushed yet, so everything so far is
        undoable from the snapshot in step 2. After the push it is not.

        ## 6. Push, bottom-up

            git push --force-with-lease origin <branch>

        One branch at a time, parents first, so a reviewer never sees a child
        without its parent. A plain `--force` is blocked by a hook, and so is a
        lease push where the remote has moved since your last fetch - if the guard
        fires, fetch and re-read the remote commits before doing anything else.

        ## 7. Retarget the bases

        When the bottom of the stack merged, its child's PR still points at a
        deleted branch:

            gh pr edit <number> --base <new-base>

        Report the final state: branch, PR number, base, and CI status.
      '';
    };
}
