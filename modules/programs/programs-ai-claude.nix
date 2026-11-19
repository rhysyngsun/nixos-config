{ ... }:
{
  flake.modules.homeManager.programs-ai-claude =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      rules = {
        # Tone and length guidance, not just the emdash rule it started as. The
        # default failure modes are all additive: a paragraph recapping a diff
        # that is already on screen, a praise opener, a caveat restated for the
        # third time, and - worst in anything that outlives the session - an
        # edit to a PR body or code comment that narrates its own history
        # instead of just being the new text. Each bullet names the behavior
        # rather than asking for "concise", because "concise" is advice and
        # these are checkable.
        #
        # The deliverable bullet is the same instinct pointed at output that
        # leaves the session. Trimming a standup draft is the single most
        # repeated correction in the transcript history - always the same
        # correction, always an announcements section nobody asked for - and a
        # bullet about reply length never reached it, because a standup post is
        # not a reply.
        style = ''
          Rules:
          - Use a single dash (`-`) instead of emdash unless emdash is semantically
            significant to code

          # Writing to me

          - Answer at the length the question deserves. A one-line change gets a
            one-line reply. Do not restate a diff I can read, and do not append a
            "what I did" summary to work that is already visible in the tool output
            above it.
          - No praise openers, no congratulating me on a question, no "you're
            absolutely right". Lead with the answer.
          - Do not explain things I did not ask about. If I want background I will
            ask for it.
          - State a caveat once, where it is load-bearing. Do not repeat a risk I
            have already acknowledged, and do not pad a correct answer with
            disclaimers.
          - Report outcomes plainly. "Three tests failed" is a sentence, not an
            apology.
          - A deliverable contains only what I asked for. No extra sections, no
            announcement block in a standup, nothing added to a PR body or a
            comment because it seemed useful while you were in there.

          # Writing prose that ships

          When you edit text that gets read on its own - a PR description, an issue
          body, a GitHub comment, a code comment, a docstring, a commit message, a
          README - the result must read as if it had always said that.

          - No references to the previous version: no "updated to", "changed from",
            "previously this said", "now also handles", "as mentioned above".
          - No narrating your own edit inside the artifact.
          - Edit history belongs in git and the PR timeline, not in the text.
          - If what you changed is not obvious from the diff, tell me in chat.
        '';
        # The code-navigation section exists because the lean-ctx MCP tools are
        # *deferred*: they are not in the loaded tool list and need a ToolSearch
        # round trip before they are callable, while Read/Bash always are. A rules
        # file is always in context, so this is the only place the selector can be
        # stated where it will actually be seen. Because `mcpServers` below is
        # delivered through home-manager's generated plugin (named
        # `claude-code-home-manager`) rather than a bare user-level MCP config, the
        # tool names are `mcp__plugin_<plugin>_<server>__<tool>`, NOT
        # `mcp__<server>__<tool>`;
        # getting that wrong makes the ToolSearch return nothing and the agent fall
        # back to Bash, which is exactly what upstream's own SKILL.md used to do.
        #
        # This used to say the Read/Grep/Glob/Bash -> ctx_* swap the server's own
        # instructions demand was "unwinnable against pre-approved `Bash(rg:*)` and
        # is not attempted here". It is attempted now, from the permission side
        # rather than by asking: the deny-only PreToolUse guard in
        # programs-ai-lean-ctx.nix blocks Grep, Glob and leading-token `rg`/`grep`/
        # `find` inside a lean-ctx-indexed project. Prose alone never moved the
        # needle, because a deferred tool loses to a free one no matter what a
        # rules file says.
        #
        # So this section's job changed. It is no longer a plea; it is the recipe
        # the agent needs *after* the guard denies something, which is why the
        # selector and the exact replacement calls are both spelled out. Read is
        # deliberately not gated, so `ctx_read` stays a suggestion.
        #
        # `ctx_search(action="regex")` and `ctx_glob` lead because they are the
        # direct Grep/Glob substitutes. `ctx_callgraph` and `action="symbol"` need
        # a tree-sitter grammar and do nothing in a nix repo, where every .nix file
        # indexes as `Kind: text` - hence the explicit caveat rather than a blanket
        # promise. The `pls`/`rg` lines stay true and stay last.
        tools = ''
          # Code navigation

          In a lean-ctx-indexed project, `Grep`, `Glob` and a bare `rg`/`grep`/`find`
          are **blocked by a hook** - route code search through lean-ctx instead. The
          tools are deferred, so load them in one call first:

              ToolSearch(query="select:mcp__plugin_claude-code-home-manager_lean-ctx__ctx_compose,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_search,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_glob,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_read")

          Then:

          - `ctx_search(action="regex", pattern=..., path=...)` - replaces `Grep`. Ranked,
            compressed matches with enclosing-symbol annotations, and it skips credential
            files by boundary policy rather than reading them.
          - `ctx_glob(pattern=...)` - replaces `Glob`.
          - `ctx_compose(task=...)` - ranked files plus inline source for one question, in
            one call. Best first move in unfamiliar code.
          - `ctx_read(mode="signatures"|"map")` - a file's shape without its body.

          Needs a tree-sitter grammar, so useless where files index as `Kind: text`
          (every `.nix` file, for one - check `lean-ctx index status`):

          - `ctx_search(action="symbol")` - exact definition
          - `ctx_callgraph` - callers and callees

          Searching *outside* the project - `/nix/store`, a vendored source tree, `/etc` -
          is not blocked; use `rg` there as normal. If you genuinely need raw search inside
          the project (binary files, a regex `ctx_search` cannot express), append
          ` # lean-ctx:bypass` to the shell command.

          Keep using `Bash` for running commands - not `ctx_shell`. The lean-ctx
          server is allowed whole-server, so routing commands through `ctx_shell`
          would sidestep the per-command `Bash(...)` permission gates.

          # CLI tools
          Rules:
          - You may execute read-only operations of CLI tools

          Some standard CLI tools have been replaced with alternatives:

          - `ls` is aliased to `pls` - run `pls -h` to see example usages
          - Use ripgrep (`rg`) instead of `grep`, for known paths and one-off greps
        '';
        guardrails = ''
          - If you are executing a pre-approved plan and need to change direction in the middle of implementation, don't just implement it, show me a revised plan so I can approve it.
          - If you do not have connection information for a database or service ask for the credentials do not connect to one you find.
          - Ask for confirmation before commiting code or pushing.
          - Ask for confirmation before creating issues, commenting, or anything else that writes to github.
          - Do not expand the scope of a requested change beyond what has been approved. Set findings aside and ask for approval.
        '';
        k8s = ''
          - When using kubectl **always** explicitly specify the context in commands, don't depend on the default context as that can change out from under you.
        '';
        # Every line here is a postmortem of a script written in this
        # transcript history, not general shell advice: a diagnostic that
        # hardcoded a /tmp log path and read back a pre-reboot log as if it
        # were fresh, a guard whose pipeline exited 0 because nothing matched,
        # and a jq call that parsed a filename beginning with `-` as a flag.
        # Generic "write careful shell" guidance is unfalsifiable; each of
        # these names a specific thing to check.
        shell = ''
          # Scripts and shell

          - Every script you write starts with `set -euo pipefail`.
          - No hardcoded `/tmp` paths. Use `mktemp -d`, or the session scratchpad
            directory when one is provided. A fixed path under `/tmp` survives a
            reboot, so the next run reads a stale file and believes it is fresh.
          - Put anything beyond a single pipeline in a script file rather than
            inlining it, so it can be read and re-run.
          - Pass filenames as `-- <name>` or `./<name>` so one beginning with `-`
            is not parsed as a flag.
          - A pipeline that exits 0 because nothing matched is not a pipeline that
            passed. Distinguish the two explicitly in any guard, and watch for
            SIGPIPE closing a pipe early under `pipefail`.
          - Run the script yourself once before calling it done. If it writes or
            deletes anything, give it a `--dry-run` and run that first.
        '';
        # The gitleaks migration is the case this exists for: a hook that
        # reported green on every commit while matching nothing at all, and a
        # later exclude pattern that skipped the one directory holding real
        # credentials. Both passed CI. Neither was caught by reading the diff -
        # only by making the check fail on purpose.
        ci = ''
          # Hooks, guards and CI checks

          - After adding or changing a hook, lint rule, guard or test, prove it
            fires: introduce a deliberate violation, run it, confirm it fails,
            then revert. A green run on an unchanged tree is not evidence the
            check works - it is equally consistent with the check matching
            nothing.
          - Never add an exclude or ignore pattern to a secrets scanner or a
            linter without telling me which paths it now skips and why.
        '';
      };

      # Advisory, never blocking. Buggy agent-authored shell is the single
      # largest friction category in this machine's transcript history, and the
      # bugs are the kind a linter names: unquoted expansions, a missing
      # `set -euo pipefail`, a `cd` whose failure goes unchecked.
      #
      # PostToolUse rather than PreToolUse on purpose - the file has to exist to
      # be linted, and the point is to put the findings in front of the model
      # right after it writes, not to veto the write.
      #
      # `additionalContext` is the advisory channel. The exit-2 path also
      # reaches the model but frames it as the tool call having failed, which is
      # wrong for a style warning on a file that was written exactly as
      # intended.
      #
      # zsh is deliberately out of scope: shellcheck cannot parse it and reports
      # the whole file as a syntax error, which is noise rather than a finding.
      # Hence a `.sh`/`.bash` extension or an explicit sh/bash shebang, nothing
      # looser.
      shellcheckHook =
        pkgs.writers.writePython3Bin "claude-shellcheck-hook"
          {
            flakeIgnore = [
              "E501" # the advisory text is a single long line
            ];
          }
          ''
            import json
            import os
            import subprocess
            import sys

            SHELLCHECK = "${pkgs.shellcheck}/bin/shellcheck"

            EXTENSIONS = (".sh", ".bash")
            SHEBANGS = ("sh", "bash", "dash", "ksh")


            def silent():
                sys.exit(0)


            def is_shell(path):
                if path.endswith(EXTENSIONS):
                    return True
                try:
                    with open(path, "r", encoding="utf-8", errors="replace") as fh:
                        first = fh.readline()
                except OSError:
                    return False
                if not first.startswith("#!"):
                    return False
                # `#!/usr/bin/env bash` and `#!/bin/sh -e` both reduce to the
                # interpreter basename once env and flags are dropped.
                toks = [t for t in first[2:].split() if not t.startswith("-")]
                if not toks:
                    return False
                name = os.path.basename(toks[0])
                if name == "env" and len(toks) > 1:
                    name = os.path.basename(toks[1])
                return name in SHEBANGS


            def main():
                try:
                    payload = json.loads(sys.stdin.read())
                except Exception:
                    silent()

                path = (payload.get("tool_input") or {}).get("file_path") or ""
                if not path or not os.path.isfile(path):
                    silent()
                if not is_shell(path):
                    silent()

                try:
                    proc = subprocess.run(
                        [SHELLCHECK, "--format=gcc", "--", path],
                        capture_output=True,
                        text=True,
                        timeout=15,
                    )
                except Exception:
                    silent()

                findings = proc.stdout.strip()
                if proc.returncode == 0 or not findings:
                    silent()

                json.dump(
                    {
                        "hookSpecificOutput": {
                            "hookEventName": "PostToolUse",
                            "additionalContext": (
                                "shellcheck on " + path + ":\n" + findings + "\n\n"
                                "Fix these before presenting the script as done, or say why each one does not apply."
                            ),
                        }
                    },
                    sys.stdout,
                )
                sys.exit(0)


            main()
          '';
    in
    {
      programs.git.ignores = [ ".claude/" ];
      programs.claude-code = {
        enable = true;
        inherit rules;

        mcpServers.lean-ctx = {
          args = [
            "mcp"
          ];
          command = "${pkgs.lean-ctx}/bin/lean-ctx";

          # Deliberately not `tools = [ "*" ]`, which is what used to be here.
          # `mcpServers` is typed `attrsOf jsonFormat.type`, so that key was
          # copied verbatim into the plugin's `.mcp.json`, where Claude Code's
          # stdio server schema has no `tools` field at all - a silent no-op,
          # which is why the profile stayed at `power` the whole time.
          #
          # `standard` is 18 tools and keeps read/search/glob/tree/compose/patch -
          # every tool the mapping in the server's own instructions names. It is
          # chosen to keep the ToolSearch result set legible, NOT to clear any
          # threshold.
          #
          # THE PROFILE SIZE DOES NOT AFFECT DEFERRAL. This comment used to claim
          # that `power`'s 78 tools, stacked on toolhive-swe-prod/qa and witan,
          # pushed Claude Code past a tool-count limit past which it strips MCP
          # schemas and leaves only names behind `ToolSearch`. That is false, and
          # shrinking the profile was therefore never going to change anything.
          # Measured on claude-code 2.1.223, by asking a `-p` session to call a
          # ctx_* tool without a prior ToolSearch:
          #
          #   every server (462 tools) ................. deferred
          #   lean-ctx ALONE, --strict-mcp-config
          #     (18 MCP tools, 51 total) ............... STILL deferred
          #
          # Deferral is unconditional for MCP tools. The only switch is
          # `ENABLE_TOOL_SEARCH=false` (or the blunter
          # `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1`, which also strips context
          # management and structured outputs). Both work - and both are refused
          # here, because turning deferral off inlines every MCP schema:
          #
          #   deferral on (today) ....................... ~47k prompt
          #   deferral off, every server ................ ~287.6k prompt
          #   deferral off, toolhive dropped ............ ~107.1k prompt
          #   deferral off, lean-ctx only ............... ~62.4k prompt
          #
          # ~240k of context for tool schemas is not worth it. Note also that
          # `deniedMcpServers` cannot be used to trim the surface per-repo: it has
          # no effect on plugin-provided servers in any identifier form
          # (`plugin:<plugin>:<server>`, bare name, or URL), which all leave every
          # server connected.
          #
          # So the incentive is fixed from the other end instead - the deny-only
          # PreToolUse guard in programs-ai-lean-ctx.nix. See that file.
          #
          # The env var rather than config.toml because `lean-ctx tools` reports
          # the var as overriding the file. config.toml is managed too, by
          # programs-ai-lean-ctx.nix, and its `tool_profile` must agree with the
          # value set here.
          #
          # RE-DERIVE THE PROFILE CONTENTS WHEN lean-ctx IS BUMPED in
          # nvfetcher.toml:  LEAN_CTX_TOOL_PROFILE=standard lean-ctx tools
          env.LEAN_CTX_TOOL_PROFILE = "standard";
        };

        settings = {
          theme = "auto";
          verbose = true;

          # `settings.hooks` lists concatenate across home-manager modules, so
          # this sits alongside the witan reindex entry from
          # programs-ai-claude-mit.nix rather than replacing it - both fire on
          # a write, in list order.
          hooks.PostToolUse = [
            {
              # Full-match regex over the tool name, so no trailing `.*` is
              # needed for these three - but a bare prefix would match nothing.
              matcher = "Write|Edit|MultiEdit";
              hooks = [
                {
                  type = "command";
                  command = "${shellcheckHook}/bin/claude-shellcheck-hook";
                  # shellcheck's own run is bounded at 15s inside the script,
                  # and it exits silently on timeout, so this never decides an
                  # outcome.
                  timeout = 20;
                }
              ];
            }
          ];

          # Derived from the same discovery as `skills` above, so a skill that
          # grows a scripts/ directory or a cache directory is covered by the
          # next repin with no edit here.
          permissions.allow = [
            # Whole-server allow for the lean-ctx MCP server declared above.
            # The bare `mcp__<server>` form is the whole-server rule, and the
            # server name is the one Claude Code derives for a server declared
            # through a home-manager plugin - `plugin:<plugin>:<server>` with
            # the colons flattened to underscores - not the `lean-ctx` written
            # above. The three other servers on this machine are already
            # allowed this way in programs-ai-claude-mit.nix; lean-ctx was the
            # only one missing, so a ctx_* call prompted while every Bash
            # alternative below (rg, grep, find, sed) was pre-approved. That
            # gradient pointed away from the tools we want used.
            #
            # Covers the writes as well as the reads. ctx_patch and ctx_edit
            # touch the working tree, but they are the compressed path to the
            # same edits the built-in Edit tool makes unprompted, and
            # ctx_shell inherits lean-ctx's own 223-command allowlist and path
            # jail (`lean-ctx doctor`).
            "mcp__plugin_claude-code-home-manager_lean-ctx"

            "Bash(docker compose:*)"
            # Also covers `uv run ruff …`, so ruff needs no entry of its own.
            "Bash(uv run:*)"
            "Bash(pls:*)"
            "Bash(grep:*)"
            "Bash(sed:*)"
            "Bash(gh issue:*)"
            # Needed by the `restack` skill in programs-ai-claude-git.nix,
            # which cannot enumerate a stack without `gh pr list`.
            "Bash(gh pr:*)"
            "Bash(gh repo:*)"
            "Bash(gh run:*)"
            "Bash(gh stack:*)"
            "Bash(pre-commit:*)"
            "Bash(prek:*)"
            "Bash(echo \"EXIT=$?\")"
            "Bash(rg:*)"
            "Bash(find:*)"
            "Bash(command -v:*)"
            "Bash(gitleaks:*)"

            # The ~/.claude/skills/** read allow lives in
            # programs-ai-claude-mit.nix (`skillTreeAllows`), not here. It is
            # useless on its own: the skills are home-manager symlinks into the
            # store, and an allow rule only applies when the requested path and
            # every path it resolves to match, so the rule has to be emitted
            # together with the store-path hops - which need the agent-kit
            # `src` that only that module has.
          ]
          ++ (builtins.map (subcmd: "Bash(git ${subcmd}:*)") [
            "add"
            # Deliberately not `git checkout *`: that also covered
            # `git checkout .` and `git checkout -- <path>`, which discard
            # uncommitted work without asking - a sharp edge in a repo where
            # every build recipe runs `git add .`. These two are the
            # non-destructive intents; `git restore` stays unlisted on purpose.
            "checkout -b"
            "diff"
            "--no-pager diff"
            "log"
            "fetch"
            "rebase"
            "show"
            "switch"
            "worktree"
          ]);

          # sed gets the opposite treatment from git checkout above, on purpose:
          # its destructive form is a flag rather than a subcommand, and the
          # common safe call (`sed 's/a/b/' file`) leads with no flag at all, so
          # narrowing the allow would prompt on ordinary read-only use. ask
          # outranks allow, so keep the broad allow and carve out the writing
          # forms here. No space before the * so `sed -i.bak` is caught too.
          permissions.ask = [
            "Bash(sed -i*)"
            "Bash(sed --in-place*)"
          ];
        };
      };
    };
}
