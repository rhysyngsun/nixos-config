{pkgs, lib, ...}: {
  home.packages = with pkgs; [
    pi-coding-agent
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
  };

  # programs.pi-coding-agent = {
  #   enable = true;
  #   configDir = "${config.xdg.configHome}/pi/agent";
  #   settings = {
  #     theme = "dark";
  #   };
  # };
}
