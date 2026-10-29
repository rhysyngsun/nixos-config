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
        style = ''
          Rules:
          - Use a single dash (`-`) instead of emdash unless emdash is semantically significant to code
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
      };
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
