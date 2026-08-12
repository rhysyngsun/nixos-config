{ ... }:
{
  flake.modules.homeManager.programs-ai-pi-local =
    {
      config,
      pkgs,
      ...
    }:
    let
      jsonFormat = pkgs.formats.json { };
    in
    {
      home.packages = with pkgs; [
        lmstudio
      ];

      programs.git.ignores = [".agents/"];
      programs.pi-coding-agent = {
        enable = true;
        package = pkgs.pkgs-unstable.pi-coding-agent;
        extraPackages = with pkgs; [
          nodejs
          python3
        ];
        settings = {
          theme = "dark";
          packages = [
            "npm:pi-lmstudio"
            "npm:pi-subagents"
            "npm:@bacnh85/pi-plan"
            "npm:pi-subdir-context"
          ];
        };
        models = {
          providers = {
            lmstudio = {
              baseUrl = "http://localhost:1234/v1";
              api = "openai-completions";
              models = [
                {
                  id = "google/gemma-4-26b-a4b";
                  contextWindow = 128000;
                  maxTokens = 32000;
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  cost = {
                    input = 0;
                    output = 0;
                    cacheRead = 0;
                    cacheWrite = 0;
                  };
                }
              ];
            };
            ollama = {
              baseUrl = "http://localhost:11434/v1";
              api = "openai-completions";
              apiKey = "ollama";
              models = [
                {
                  id = "qwen3-coder:30b";
                  name = "qwen3-coder";
                  contextWindow = 256000;
                  maxTokens = 32000;
                  cost = {
                    input = 0;
                    output = 0;
                    cacheRead = 0;
                    cacheWrite = 0;
                  };
                }
                {
                  id = "gemma4:e4b";
                  name = "gemma4:e4b";
                  contextWindow = 128000;
                  maxTokens = 32000;
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  cost = {
                    input = 0;
                    output = 0;
                    cacheRead = 0;
                    cacheWrite = 0;
                  };
                }
                {
                  id = "gemma4:12b";
                  name = "gemma4:12b";
                  reasoning = true;
                  input = [
                    "text"
                    "image"
                  ];
                  contextWindow = 256000;
                  maxTokens = 32000;
                  cost = {
                    input = 0;
                    output = 0;
                    cacheRead = 0;
                    cacheWrite = 0;
                  };
                }
              ];
            };
          };
        };
      };

      home.file."${config.programs.pi-coding-agent.configDir}/pi-plan-mode.json".source =
        jsonFormat.generate "pi-plan-mode.json"
          {
            thinkingLevel = "inherit";
            defaultPlanTools = [
              "read"
              "bash"
              "grep"
              "find"
              "ls"
            ];
            implementationPlanRetention = "keep";
            defaultPlanExportPath = "PLAN.md";
            safeSubcommands = {
              git = [
                "status"
                "log"
                "rev-parse"
                "blame"
              ];
              gh = [
                "pr view"
                "pr list"
                "issue view"
                "issue list"
              ];
            };
          };
    };
}
