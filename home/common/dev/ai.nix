{pkgs, lib, ...}: {
  home.packages = with pkgs; [
    pi-coding-agent
    ollama-vulkan
  ];
  programs.claude-code = let
    mkSkills = category: names: (
      lib.attrsets.genAttrs names (name: "${pkgs.mit.agent-kit.src}/skills/${category}/${name}")
    );
  in {
    enable = true;
    skills = lib.attrsets.mergeAttrsList (lib.attrsets.mapAttrsToList mkSkills {
      process = [
        "create-ol-github-issue"
        "create-ol-pull-request"
        "create-ol-rfc-discussion"
        "generate-standup"
      ];
      python = [
        "uv-python-workflow"
      ];
    });
    rules = {
      tools = ''
        # CLI tools

        Some standard CLI tools have been replaced with alternatives:

        - `ls` is aliased to `pls` - run `pls -h` to see example usages
      '';
      guardrails = ''
        If you do not have connection information for a database or service ask for the credentials do not connect to one you find.
      '';
    };
  };

  home.shellAliases = {
    claude-personal = ''CLAUDE_CONFIG_DIR=~/.claude-personal claude "$@"'';
  };
  # programs.pi-coding-agent = {
  #   enable = true;
  #   configDir = "${config.xdg.configHome}/pi/agent";
  #   settings = {
  #     theme = "dark";
  #   };
  # };
}
