{ ... }:
{
  flake.modules.homeManager.programs-ai-claude-mit =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      # Skills are read straight out of the vendored agent-kit checkout rather
      # than copied in: the attr name becomes the directory under
      # ~/.claude/skills/, the value the store path holding its SKILL.md.
      mkSkillsFrom =
        dir: names: lib.attrsets.genAttrs names (name: "${pkgs.mit.agent-kit.src}/${dir}/${name}");
      skillsFrom = dirs: lib.attrsets.mergeAttrsList (lib.attrsets.mapAttrsToList mkSkillsFrom dirs);

      skillDirs = {
        "skills/process" = [
          "create-ol-github-issue"
          "create-ol-pull-request"
          "create-ol-rfc-discussion"
          "generate-standup"
          "renovate-security-triage"
        ];
        "skills/python" = [
          "uv-python-workflow"
        ];
        "skills/workflow" = [
          "creating-skills"
        ];
      };

      # witan's skills ship inside the two MCP server packages rather than the
      # shared catalogue. Work profile only: they steer tools the personal
      # profile has no witan server to answer with.
      witanSkillDirs = {
        "mcp/servers/witan/witan/skills" = [
          "witan-memory"
          "witan-project-tracker"
          "witan-task"
          "witan-workflow"
        ];
        "mcp/servers/witan-code/witan_code/skills" = [
          "witan-code"
        ];
      };

      skills = skillsFrom skillDirs;
      witanSkills = skillsFrom witanSkillDirs;

      # Skills that ship helpers under scripts/ need every one of them
      # pre-approved or the skill stalls on a permission prompt mid-run. Read
      # the names out of the pinned checkout so the lists above stay the single
      # place a new skill has to be declared. Most skills ship no scripts/ at
      # all, which pathExists short-circuits.
      skillScriptNames =
        subdir:
        let
          dir = "${pkgs.mit.agent-kit.src}/${subdir}/scripts";
        in
        lib.optionals (builtins.pathExists dir) (
          lib.filter (lib.hasSuffix ".sh") (
            lib.attrNames (lib.filterAttrs (_: type: type == "regular") (builtins.readDir dir))
          )
        );

      # Claude matches the command it is about to run against these literally,
      # so each script needs every spelling it can be invoked under: both home
      # forms for normal sessions, plus the repo-relative one for sessions
      # started inside the agent-kit checkout itself.
      skillScriptAllows =
        dirs:
        lib.flatten (
          lib.mapAttrsToList (
            dir: names:
            map (
              name:
              map (script: [
                "Bash(~/.claude/skills/${name}/scripts/${script}:*)"
                "Bash(${config.home.homeDirectory}/.claude/skills/${name}/scripts/${script}:*)"
                "Bash(./${dir}/${name}/scripts/${script}:*)"
              ]) (skillScriptNames "${dir}/${name}")
            ) names
          ) dirs
        );

      rules = {
        style = ''
          Don't ever use emdashes in descriptive text - it's ok if it's necessary in code.
        '';
        tools = ''
          # CLI tools
          Rules:
          - You may execute read-only operations of CLI tools

          Some standard CLI tools have been replaced with alternatives:

          - `ls` is aliased to `pls` - run `pls -h` to see example usages
        '';
        guardrails = ''
          - If you do not have connection information for a database or service ask for the credentials do not connect to one you find.
        '';
      };

      mkHook =
        {
          command,
          matcher ? "",
          timeout ? null,
        }:
        {
          inherit matcher;
          hooks = [
            (
              {
                type = "command";
                inherit command;
              }
              // lib.optionalAttrs (timeout != null) { inherit timeout; }
            )
          ];
        };
    in
    {
      programs.git.ignores = [".claude/"];
      programs.claude-code = {
        enable = true;
        inherit rules;
        skills = skills // witanSkills;

        # Upstream's snippet runs `uvx --from git+…agent-kit`, re-resolving from
        # git main on every launch; point at the pinned derivation instead.
        # witan-code needs no entry of its own — `witan serve` mounts its tools
        # in-process.
        mcpServers.witan = {
          type = "stdio";
          command = lib.getExe pkgs.mit.witan;
          args = [ "serve" ];
          env.WITAN_AUTHOR = "Nathan Levesque";
        };

        settings = {
          theme = "auto";
          verbose = true;

          # Derived from the skills installed above; the witan dirs go through
          # the same generator so they are covered if they ever grow scripts.
          permissions.allow = skillScriptAllows (skillDirs // witanSkillDirs) ++ [
            "Read(//home/nathan/.cache/renovate-security-triage/**)"
          ];

          # Mirrors what `witan setup --agent claude` merges in. Bare command
          # names on purpose: witan-code's hooks are mounted as `witan code …`,
          # so only `witan` has to be on PATH. The 15s prompt-path timeouts are
          # upstream's — a hung git or store read must degrade to no context
          # rather than stall the session.
          hooks = {
            SessionStart = [ (mkHook { command = "witan code session-init"; }) ];
            UserPromptSubmit = [
              (mkHook {
                command = "witan inject-context";
                timeout = 15;
              })
              (mkHook {
                command = "witan code inject-context";
                timeout = 15;
              })
            ];
            PostToolUse = [
              (mkHook {
                command = "witan code reindex-hook";
                matcher = "Edit|Write";
              })
            ];
            Stop = [
              (mkHook {
                command = "witan session-checkpoint";
                timeout = 15;
              })
              (mkHook {
                command = "witan code checkpoint";
                timeout = 15;
              })
            ];
          };
        };
      };

      home = {
        # Required, not just convenient: the hooks above shell out to a bare
        # `witan`, so it has to be on PATH for the whole session and not merely
        # reachable as the MCP server's `command`.
        packages = [ pkgs.mit.witan ];
      };

    };
}
