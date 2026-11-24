{ ... }:
{
  # Personal skills, discovered out of github.com/rhysyngsun/agent-skills the
  # same way programs-ai-claude-mit.nix discovers agent-kit's. Separate module
  # rather than a second root inside that one, because the two checkouts are
  # pinned, versioned and owned independently - and because this one is flat
  # (`skills/<name>/`) with no category layer.
  flake.modules.homeManager.programs-ai-claude-personal =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      src = pkgs.localSources.rhysyngsun-agent-skills.src;
      root = "skills";

      # Opt-out, not opt-in: everything in the repo is installed unless named
      # here, so adding a skill upstream is a repin and no edit to this file.
      excludedSkills = [ ];

      subdirsOf =
        rel:
        lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir "${src}/${rel}"));

      # Keyed on SKILL.md presence rather than on being a directory, so
      # anything else that lands directly under skills/ - a template, a
      # fixture, a category layer if the repo ever grows one - is skipped
      # instead of being installed as a nameless skill.
      isSkillDir = rel: builtins.pathExists "${src}/${rel}/SKILL.md";

      # name -> repo-relative directory. Single source of truth for the
      # installed skills and both derived allowlists below.
      skillPaths = lib.removeAttrs (lib.listToAttrs (
        map (rel: lib.nameValuePair (baseNameOf rel) rel) (
          lib.filter isSkillDir (map (n: "${root}/${n}") (subdirsOf root))
        )
      )) excludedSkills;

      # A store-path *string*, not a Nix path. home-manager's `mkSkillEntry`
      # tests `isPathLikeContent`, which accepts a string under `builtins.storeDir`
      # and symlinks the whole directory - so a skill that grows a references/
      # or scripts/ tree is installed entire with no change here. (The `rules`
      # option is the opposite case and needs `readFile`; see
      # programs-ai-claude.nix.)
      skills = lib.mapAttrs (_: rel: "${src}/${rel}") skillPaths;

      # Progressive disclosure: a SKILL.md routinely tells the agent to read a
      # sibling file under its own directory, and an allow rule for a symlinked
      # path applies only when the requested path *and* every path it resolves
      # to match. The first two hops are already allowed by `skillTreeAllows` in
      # programs-ai-claude-mit.nix:
      #
      #   ~/.claude/skills/<name>/references/x.md            <- requested
      #   /nix/store/<hash>-home-manager-files/.claude/...    <- home-manager link
      #   /nix/store/<hash>-agent-skills-<rev>/skills/...     <- the real file
      #
      # so only the third, this checkout's own, is added here. Per-skill rather
      # than `${src}/**`, which would hand over the whole repository including
      # rules/.
      skillTreeAllows = lib.mapAttrsToList (_: path: "Read(/${path}/**)") skills;

      # A skill shipping helpers under scripts/ needs each one pre-approved or
      # the skill stalls on a permission prompt mid-run. Nothing ships one
      # today; reading the names out of the pinned checkout means the first one
      # that does needs no edit here either.
      #
      # The .sh filter matches programs-ai-claude-mit.nix: a scripts/*.py is
      # documented as `uv run scripts/<name>.py` and is already covered by the
      # `Bash(uv run:*)` allow.
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
      # so each script needs every spelling it can be invoked under. The
      # `bash `-prefixed twin is not optional: Claude strips a fixed set of
      # wrappers before matching - timeout, time, nice, nohup, stdbuf, command,
      # builtin, noglob - and `bash` is not among them.
      skillScriptAllows = lib.flatten (
        lib.mapAttrsToList (
          name: rel:
          map (
            script:
            map
              (prefix: "Bash(${prefix}${config.home.homeDirectory}/.claude/skills/${name}/scripts/${script}:*)")
              [
                ""
                "bash "
              ]
          ) (skillScriptNames rel)
        ) skillPaths
      );
    in
    {
      programs.claude-code = {
        inherit skills;

        settings.permissions.allow = skillTreeAllows ++ skillScriptAllows;
      };
    };
}
