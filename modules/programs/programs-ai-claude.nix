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
        # Only the four tools with no built-in equivalent are promoted. The server's
        # own instructions demand a wholesale Read/Grep/Glob/Bash -> ctx_* swap; that
        # fight is unwinnable against pre-approved `Bash(rg:*)` and is not attempted
        # here. The `pls`/`rg` lines stay true and stay last.
        tools = ''
          # Code navigation

          Before grepping or reading files to understand unfamiliar code, load the
          lean-ctx tools in one call and start with `ctx_compose`:

              ToolSearch(query="select:mcp__plugin_claude-code-home-manager_lean-ctx__ctx_compose,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_search,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_read,mcp__plugin_claude-code-home-manager_lean-ctx__ctx_callgraph")

          These have no built-in equivalent:

          - `ctx_compose(task)` - ranked files plus inline source for one question, in one call
          - `ctx_search(action="symbol"|"semantic")` - exact definition, or search by meaning
          - `ctx_callgraph` - callers and callees
          - `ctx_read(mode="signatures"|"map")` - a file's shape without its body

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
          # `power` exposes all 78 ctx_* tools. Stacked on toolhive-swe-prod,
          # toolhive-swe-qa and witan, that pushes Claude Code past the point
          # where it strips every MCP schema out of the tool list and leaves
          # only tool *names* behind `ToolSearch`. A deferred tool costs an
          # extra round trip and the built-in `Read` costs nothing, so the
          # model never reached for one: zero ctx_* calls across ~60 sessions,
          # against 3099 Bash. `standard` is 17 tools and keeps
          # read/search/glob/tree/compose/patch - every tool the mapping in the
          # server's own instructions actually names.
          #
          # The env var rather than config.toml because `lean-ctx tools`
          # reports the var as overriding the file, and
          # ~/.config/lean-ctx/config.toml is unmanaged here - same reason
          # programs-ai-pi-local.nix will not write to it.
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
