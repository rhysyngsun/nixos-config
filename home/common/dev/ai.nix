{config, pkgs, ...}: {
  home.packages = [
    pkgs.unstable.ollama-vulkan
    pkgs.claude-code
    (pkgs.writeShellScriptBin "crush-configured" ''
      export ANTHROPIC_API_KEY="$( cat ${config.sops.secrets."llms/anthropic/api_key".path} )"
      export OPENROUTER_API_KEY="$( cat ${config.sops.secrets."llms/openrouter/api_key".path} )"

      ${config.programs.crush.package}/bin/crush
    '')
  ];
  programs.crush = {
    enable = true;
  };
}
