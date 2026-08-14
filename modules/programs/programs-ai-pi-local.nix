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
            };
          };
        };
      };
    };
}
