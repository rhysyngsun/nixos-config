{config, pkgs, ...}: {
  home.packages = with pkgs; [
    # pkgs-unstable.ollama-cuda
    pi-coding-agent
    # pkgs.claude-code
    # (pkgs.writeShellScriptBin "crush-configured" ''
    #   export ANTHROPIC_API_KEY="$( cat ${config.sops.secrets."llms/anthropic/api_key".path} )"
    #   export OPENROUTER_API_KEY="$( cat ${config.sops.secrets."llms/openrouter/api_key".path} )"
    #
    #   ${config.programs.crush.package}/bin/crush
    # '')
  ];
  programs.claude-code = {
    enable = true;
  };
  # programs.crush = {
  #   enable = true;
  #   settings = {
  #     providers = {
  #       ollama = {
  #         name = "Ollama";
  #         base_url = "http://localhost:11434/v1/";
  #         type = "openai-compat";
  #         models = [
  #           {
  #             name = "Qwen 33.";
  #             id = "qwen3.5";
  #             context_window = 256000;
  #             default_max_tokens = 20000;
  #           }
  #         ];
  #       };
  #     };
  #   };
  # };
  # programs.pi-coding-agent = {
  #   enable = true;
  #   configDir = "${config.xdg.configHome}/pi/agent";
  #   settings = {
  #     theme = "dark";
  #   };
  # };
}
