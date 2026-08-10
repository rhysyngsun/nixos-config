{ ... }:
{
  flake.modules.homeManager.programs-ai-claude =
    {
      config,
      pkgs,
      lib,
      ...
    }: let
      mkSkills =
        category: names:
        (lib.attrsets.genAttrs names (name: "${pkgs.mit.agent-kit.src}/skills/${category}/${name}"));
      skills = lib.attrsets.mergeAttrsList (
        lib.attrsets.mapAttrsToList mkSkills {
          process = [
            "create-ol-github-issue"
            "create-ol-pull-request"
            "create-ol-rfc-discussion"
            "generate-standup"
          ];
          python = [
            "uv-python-workflow"
          ];
          workflow = [
            "creating-skills"
          ];
        }
      );
      rules = {
        tools = ''
          # CLI tools
          Rules:
          - You may execute read-only operations of CLI tools

          Some standard CLI tools have been replaced with alternatives:

          - `ls` is aliased to `pls` - run `pls -h` to see example usages
        '';
        guardrails = ''
          If you do not have connection information for a database or service ask for the credentials do not connect to one you find.
        '';
      };
    in {
      programs.claude-code = {
        enable = true;
        inherit skills rules;
      };

      programs.claude-code-personal ={
        enable = true;
        package = null;
        inherit skills rules;
      };

      home.shellAliases = {
        claude-personal = ''CLAUDE_CONFIG_DIR=~/.claude-personal claude "$@"'';
      };
    };
}
