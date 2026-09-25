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
          "django-api-benchmark"
          "drf-api-performance"
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
      #
      # Each of those three also needs a `bash `-prefixed twin, because that is
      # how the SKILL.md files actually document the invocation. Claude strips a
      # fixed set of wrappers before matching - timeout, time, nice, nohup,
      # stdbuf, command, builtin, noglob - and `bash` is not among them, so
      # `bash <path>` never matches a bare `<path>` rule.
      skillScriptAllows =
        dirs:
        lib.flatten (
          lib.mapAttrsToList (
            dir: names:
            map (
              name:
              map (
                script:
                lib.concatMap
                  (prefix: [
                    "Bash(${prefix}~/.claude/skills/${name}/scripts/${script}:*)"
                    "Bash(${prefix}${config.home.homeDirectory}/.claude/skills/${name}/scripts/${script}:*)"
                    "Bash(${prefix}./${dir}/${name}/scripts/${script}:*)"
                  ])
                  [
                    ""
                    "bash "
                  ]
              ) (skillScriptNames "${dir}/${name}")
            ) names
          ) dirs
        );

      # agent-kit skills that retain artifacts put them at a fixed
      # ~/.cache/<skill-name>/ precisely so one allow entry survives across runs
      # (renovate-security-triage/scripts/paths.sh explains the reasoning at
      # length). Derive the entry from the same skill lists as the script
      # allows, so a new skill needs no edit here.
      #
      # Edit(), not Write(): file rules are only ever checked against Read() and
      # Edit(). A Write() rule is accepted, never consulted, and warned about at
      # startup. Edit() covers the Edit, Write and NotebookEdit tools.
      skillCacheAllows =
        dirs:
        lib.concatMap (name: [
          "Read(~/.cache/${name}/**)"
          "Edit(~/.cache/${name}/**)"
          "Read(/${config.home.homeDirectory}/.cache/${name}/**)"
          "Edit(/${config.home.homeDirectory}/.cache/${name}/**)"
        ]) (lib.flatten (lib.attrValues dirs));

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
        '';
        guardrails = ''
          - If you do not have connection information for a database or service ask for the credentials do not connect to one you find.
          - Ask for confirmation before commiting code or pushing.
          - Ask for confirmation before creating issues, commenting, or anything else that writes to github.
          - Do not expand the scope of a requested change beyond what has been approved. Set findings aside and ask for approval.
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
      programs.git.ignores = [ ".claude/" ];
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

          # Derived from the skills installed above; the witan dirs go through
          # the same generators so they are covered if they ever grow scripts
          # or a cache directory.
          permissions.allow =
            skillScriptAllows (skillDirs // witanSkillDirs)
            ++ skillCacheAllows (skillDirs // witanSkillDirs)
            ++ [
              # generate-standup's session-history step reads one JSONL per
              # session out of ~/.claude/projects/<cwd-slug>/. Read-only, and
              # the whole tree rather than one slug, because the slug is
              # whichever repo the standup is being run from.
              "Read(/${config.home.homeDirectory}/.claude/projects/**)"

              # generate-standup prepares its draft directory with a single &&
              # chain. Claude splits compound commands on && and matches each
              # subcommand against the *literal* text, before any expansion, so
              # these are matched with $HOME still written as $HOME. rm gets the
              # exact command rather than a prefix rule.
              "Bash(mkdir -p:*)"
              "Bash(chmod 700:*)"
              "Bash(printf:*)"
              ''Bash(rm -f "''${XDG_CACHE_HOME:-$HOME/.cache}/generate-standup/draft.md")''

              "Bash(docker compose:*)"
              # Also covers `uv run ruff …`, so ruff needs no entry of its own.
              "Bash(uv run:*)"
              "Bash(pls *)"
              "Bash(grep *)"
              "Bash(sed *)"
              # Deliberately not `git checkout *`: that also covered
              # `git checkout .` and `git checkout -- <path>`, which discard
              # uncommitted work without asking - a sharp edge in a repo where
              # every build recipe runs `git add .`. These two are the
              # non-destructive intents; `git restore` stays unlisted on purpose.
              "Bash(git checkout -b:*)"
              "Bash(git switch:*)"
              "Bash(git fetch *)"
              "Bash(git diff *)"
              "Bash(pre-commit *)"
              "Bash(echo \"EXIT=$?\")"
            ];

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
