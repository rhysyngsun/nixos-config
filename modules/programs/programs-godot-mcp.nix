{ ... }:
{
  flake.modules.homeManager.programs-godot-mcp =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      options.programs.godot-mcp = {
        enable = lib.mkEnableOption "Godot MCP integration with pi-coding-agent";

        projectPath = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = ''
            Path to the Godot project directory.
            When set, pi-mcp-adapter will automatically connect to that project's
            WebSocket at :6505 when the project is running.
          '';
        };

        extraPackages = lib.mkOption {
          type = with lib.types; listOf package;
          default = [ ];
          description = ''
            Extra packages available to the pi-mcp-adapter process.
            The adapter runs in a separate subprocess and needs its own PATH setup.
          '';
        };
      };

      config = lib.mkIf config.programs.godot-mcp.enable {
        programs.pi-coding-agent = {
          enable = true;
          package = lib.mkDefault pkgs.pi-coding-agent;
          extraPackages = [ pkgs.nodejs ]; # nodejs needed for pi-mcp-adapter

          settings = {
            defaultProvider = "anthropic";
            packages = [
              "npm:pi-mcp-adapter"
            ];

            compaction = {
              enabled = true;
              reserveTokens = 16384;
              keepRecentTokens = 20000;
            };

            retry = {
              enabled = true;
              maxRetries = 3;
            };
          };
        };
      };
    };
}
