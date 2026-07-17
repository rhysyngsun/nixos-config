{config, pkgs, lib, ...}: {
  home.packages = with pkgs; [
    ollama-vulkan
  ];
  programs.claude-code = {
    enable = true;
  };

  programs.claude-code-personal = let
    mkSkills = category: names: (
      lib.attrsets.genAttrs names (name: "${pkgs.mit.agent-kit.src}/skills/${category}/${name}")
    );
  in {
    enable = true;
    package = null;
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

  programs.pi-coding-agent = {
    enable = true;
    package = pkgs.pkgs-unstable.pi-coding-agent;
    # configDir = "${config.xdg.configHome}/pi/agent";
    extraPackages = with pkgs; [
      nodejs
      python3
    ];
    settings = {
      theme = "dark";
      packages = [
        "npm:@mjasnikovs/pi-task"
        "npm:@bacnh85/pi-plan"
      ];
      providers = {
        ollama = {
          baseUrl = "http://localhost:11434/v1";
          api = "openai-completions";
          apiKey = "ollama";
          models = [
            {
              id = "qwen3-coder:30b";
              name = "qwen3-coder";
            }
          ];
        };
      };
    };
  };
}
