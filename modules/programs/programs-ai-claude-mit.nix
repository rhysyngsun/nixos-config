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
      programs.claude-code = {
        enable = true;
        inherit skills;

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
          # Derived from the same discovery as `skills` above, so a skill that
          # grows a scripts/ directory or a cache directory is covered by the
          # next repin with no edit here.
          permissions.allow =
            skillScriptAllows
            ++ skillCacheAllows
            ++ [
              # Sibling MIT checkouts. Work routinely spans them - reading
              # ol-django from a mit-learn session, mitxonline from
              # ol-infrastructure - and without this each pair gets approved by
              # hand into that repo's settings.local.json. Read only: edits in
              # a sibling still prompt.
              #
              # One slash of our own on top of an already-absolute
              # homeDirectory, for a leading // in the rule. That is the
              # absolute-from-filesystem-root form; a single leading slash
              # would anchor at the settings source, which for user settings
              # is ~/.claude/, and never match.
              "Read(/${config.home.homeDirectory}/open-learnix/repos/**)"

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

      # Deployed witan: point memory, tasks and the code graph at the shared
      # cluster graph instead of the per-machine
      # ~/.local/share/witan/graph.omni. Both CLIs and the MCP server read this
      # one file, so there is nothing to repeat in `mcpServers.witan` above.
      #
      # This is the file `witan target add` writes. Declaring it here means
      # `witan target add/set/remove` can no longer edit it - it is a store
      # symlink - which is the trade this repo makes everywhere. The imperative
      # half of the flow still works: `witan login` writes a *separate*
      # tokens.json (mode 0600) into the same directory, and home-manager
      # materialises ~/.config/witan/ as a real directory around the symlink.
      #
      # `match_orgs` is the whole safety story. The target selects itself only
      # inside a checkout whose remote org is mitodl, so this repo and anything
      # else personal keeps using the local store and the honour-system
      # WITAN_AUTHOR identity. There is deliberately no fallback in the other
      # direction: inside a mitodl checkout an unreachable or unauthenticated
      # endpoint hard-fails rather than silently splitting the graph across two
      # stores, so the first witan call in a mitodl repo on a fresh machine
      # needs `witan login --target ol` before the hooks stop erroring.
      #
      # `code_transport = "mcp"` is what witan-code reads off this same block,
      # and it is not optional: it defaults to "direct", which would leave
      # indexed branches on this machine while the memory graph went to the
      # cluster, and nothing reports that as a failure. witan-council's own
      # target model ignores the key (pydantic's default extra="ignore"), which
      # is why one block can drive both servers.
      #
      # oidc_client_id is omitted on purpose - both CLIs default to the public
      # `witan-cli` device-grant client, and DeviceAuth keys its token cache on
      # (issuer, client_id), so a single login covers witan and witan-code.
      xdg.configFile."witan/config.toml".text = ''
        [targets.ol]
        remote_url = "https://witan.ol.mit.edu/mcp"
        oidc_issuer = "https://sso.ol.mit.edu/realms/ol-platform-engineering"
        oidc_audience = "witan"
        code_transport = "mcp"
        match_orgs = ["mitodl"]
      '';

      home = {
        # Required, not just convenient: the hooks above shell out to a bare
        # `witan`, so it has to be on PATH for the whole session and not merely
        # reachable as the MCP server's `command`.
        packages = [ pkgs.mit.witan ];
      };

    };
}
