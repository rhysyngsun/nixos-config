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
        tools = ''
          # CLI tools
          Rules:
          - You may execute read-only operations of CLI tools

          Some standard CLI tools have been replaced with alternatives:

          - `ls` is aliased to `pls` - run `pls -h` to see example usages
          - Use ripgrep (`rg`) instead of `grep`
        '';
        guardrails = ''
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
          tools = [
            "*"
          ];
        };

        settings = {
          theme = "auto";
          verbose = true;

          # Derived from the same discovery as `skills` above, so a skill that
          # grows a scripts/ directory or a cache directory is covered by the
          # next repin with no edit here.
          permissions.allow = [
            "Bash(docker compose:*)"
            # Also covers `uv run ruff …`, so ruff needs no entry of its own.
            "Bash(uv run:*)"
            "Bash(pls:*)"
            "Bash(grep:*)"
            "Bash(sed:*)"
            "Bash(gh repo:*)"
            "Bash(pre-commit:*)"
            "Bash(prek:*)"
            "Bash(echo \"EXIT=$?\")"
            "Bash(rg:*)"
            "Bash(find:*)"
            "Bash(command -v:*)"
            "Bash(gitleaks:*)"
          ] ++ (builtins.map (subcmd: "git ${subcmd}:*") [
              "add"
              # Deliberately not `git checkout *`: that also covered
              # `git checkout .` and `git checkout -- <path>`, which discard
              # uncommitted work without asking - a sharp edge in a repo where
              # every build recipe runs `git add .`. These two are the
              # non-destructive intents; `git restore` stays unlisted on purpose.
              "checkout -b"
              "diff"
              "fetch"
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
