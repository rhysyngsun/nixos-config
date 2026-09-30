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
      src = pkgs.mit.agent-kit.src;

      # Roots holding skill directories, repo-relative. Skills are read straight
      # out of the vendored agent-kit checkout rather than copied in: the attr
      # name becomes the directory under ~/.claude/skills/, the value the store
      # path holding its SKILL.md.
      #
      # Nested roots carry a category layer (skills/<category>/<skill>/); the
      # walk also checks the root itself, so a skill upstream flattens to
      # skills/<name>/ is still found. witan's skills ship inside the two MCP
      # server packages rather than the shared catalogue, so they need their own
      # flat roots.
      nestedRoots = [ "skills" ];
      flatRoots = [
        "mcp/servers/witan/witan/skills"
        "mcp/servers/witan-code/witan_code/skills"
      ];

      # Opt-out, not opt-in: everything upstream ships is installed unless named
      # here, so picking up a new skill is a repin and no edit to this file.
      excludedSkills = [ ];

      subdirsOf =
        rel:
        lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir "${src}/${rel}"));
      isSkillDir = rel: builtins.pathExists "${src}/${rel}/SKILL.md";

      # Keying on SKILL.md presence is also what skips the README.md that sits
      # in skills/ and in every category directory.
      skillsUnder = root: lib.filter isSkillDir (map (n: "${root}/${n}") (subdirsOf root));
      skillsUnderNested =
        root: skillsUnder root ++ lib.concatMap skillsUnder (map (c: "${root}/${c}") (subdirsOf root));

      # name -> repo-relative directory. The single source of truth for the
      # installed skills and both derived allowlists below.
      skillPaths = lib.removeAttrs (lib.listToAttrs (
        map (rel: lib.nameValuePair (baseNameOf rel) rel) (
          lib.concatMap skillsUnderNested nestedRoots ++ lib.concatMap skillsUnder flatRoots
        )
      )) excludedSkills;

      skills = lib.mapAttrs (_: rel: "${src}/${rel}") skillPaths;

      # Skills that ship helpers under scripts/ need every one of them
      # pre-approved or the skill stalls on a permission prompt mid-run. Read the
      # names out of the pinned checkout so discovery stays the single place a new
      # skill has to appear. Most skills ship no scripts/ at all, which
      # pathExists short-circuits.
      #
      # The .sh filter is deliberate: extract-style-profile and screenshot-pr
      # ship scripts/*.py instead, and their SKILL.md documents them as
      # `uv run scripts/<name>.py`, already covered by the Bash(uv run:*) allow
      # further down.
      skillScriptNames =
        rel:
        let
          dir = "${src}/${rel}/scripts";
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
      skillScriptAllows = lib.flatten (
        lib.mapAttrsToList (
          name: rel:
          map (
            script:
            lib.concatMap
              (prefix: [
                "Bash(${prefix}${config.home.homeDirectory}/.claude/skills/${name}/scripts/${script}:*)"
                "Bash(${prefix}./${rel}/scripts/${script}:*)"
              ])
              [
                ""
                "bash "
              ]
          ) (skillScriptNames rel)
        ) skillPaths
      );

      # agent-kit skills that retain artifacts put them at a fixed
      # ~/.cache/<skill-name>/ precisely so one allow entry survives across runs
      # (renovate-security-triage/scripts/paths.sh explains the reasoning at
      # length). Derived from discovery, so a new skill needs no edit here.
      #
      # Edit(), not Write(): file rules are only ever checked against Read() and
      # Edit(). A Write() rule is accepted, never consulted, and warned about at
      # startup. Edit() covers the Edit, Write and NotebookEdit tools.
      #
      # homeDirectory is already absolute - no leading slash of our own, or the
      # rule comes out as //home/<user>/... and only the ~/ twin ever matches.
      skillCacheAllows = lib.concatMap (name: [
        "Read(${config.home.homeDirectory}/.cache/${name}/**)"
        "Edit(${config.home.homeDirectory}/.cache/${name}/**)"
      ]) (lib.attrNames skillPaths);

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
        inherit rules skills;

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

        # ToolHive SWE: remote and hosted, one installation per environment
        # tier - nothing to build, package or run locally, just an endpoint
        # plus the Keycloak OAuth 2.1 consent flow Claude Code drives on first
        # connect. `/mcp` is where you authenticate, once per tier.
        #
        # Streamable HTTP only, which is what `type = "http"` selects - the
        # server speaks neither stdio nor SSE.
        #
        # The `oauth` block is required, not optional. These realms do not
        # permit anonymous Dynamic Client Registration: Keycloak's Trusted
        # Hosts policy rejects the attempt with "Host not trusted." (that is
        # `verifyHost`, keyed on the *source IP* of the registration request -
        # distinct from the redirect-URI check, which fails with "URI doesn't
        # match any trusted host"). So there is nothing to self-register from
        # here; instead every install shares one Pulumi-managed public client.
        #
        # `toolhive-swe-cli` is a public identifier, not a secret - the client
        # has no client_secret, which is why none of this needs sops. The vMCP
        # validates only tokens minted for that client.
        #
        # callbackPort 8080 is fixed for everyone and must not be varied per
        # tier or per machine: it is registered verbatim as the client's
        # redirect URI, and RFC 8252 loopback redirects are matched exactly
        # rather than negotiated. Claude Code otherwise picks a random port,
        # which Keycloak would then reject. Both tiers can share it because
        # authentication is one browser flow at a time.
        #
        # Upstream declares this in agent-config.toml for `agent-kit apply`;
        # the shape here is what its claude adapter passes through verbatim.
        # The `ci` tier is deliberately omitted - a tier without Keycloak
        # access just sits failed in `/mcp`.
        mcpServers.toolhive-swe-prod = {
          type = "http";
          url = "https://toolhive-swe.ol.mit.edu/mcp";
          oauth = {
            clientId = "toolhive-swe-cli";
            callbackPort = 8080;
          };
        };

        mcpServers.toolhive-swe-qa = {
          type = "http";
          url = "https://toolhive-swe.qa.ol.mit.edu/mcp";
          oauth = {
            clientId = "toolhive-swe-cli";
            callbackPort = 8080;
          };
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

          # Derived from the same discovery as `skills` above, so a skill that
          # grows a scripts/ directory or a cache directory is covered by the
          # next repin with no edit here.
          permissions.allow =
            skillScriptAllows
            ++ skillCacheAllows
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
              "Bash(rg:*)"
              "Bash(find:*)"
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
          # so only `witan` has to be on PATH.
          #
          # Every timeout here is upstream's, and the two families genuinely
          # differ — do not flatten them back to one number. All four were 15s
          # until agent-kit#349, which found that 15 sat *inside* the cost
          # distribution of the work it was timing rather than above it: the
          # hook was killed mid-read, the user paid the full wait, and the
          # output was thrown away. Worse on a read path, because the cold read
          # is what populates the on-disk cache — kill it and every later
          # prompt is cold too.
          #
          # `witan inject-context` is a read against the council graph,
          # measured at 16-23s cold on a graph with 19 active projects and 184
          # ready tasks, so 45s (upstream's INJECT_CONTEXT_TIMEOUT_SECONDS) is
          # headroom for a bigger graph, not a budget anything should use.
          # `witan session-checkpoint` is a WRITE (`workflow_session_end`),
          # measured at up to 51s against a deployment; killing it does not
          # drop a context block, it leaves the session open with no handoff
          # summary — invisible until someone resumes and finds nothing.
          #
          # The `witan code` pair stays at 15: the code graph is per-repo and
          # local, and its own cold read is ~10s.
          hooks = {
            SessionStart = [ (mkHook { command = "witan code session-init"; }) ];
            UserPromptSubmit = [
              (mkHook {
                command = "witan inject-context";
                timeout = 45;
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
                timeout = 60;
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
