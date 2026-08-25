{ inputs, ... }@top:
{
  flake.modules.homeManager.home-nathan =
    { pkgs, ... }:
    {
      imports = [
        inputs.stylix.homeManagerModules.stylix
        (
          { modulesPath, ... }:
          {
            # Important! We disable home-manager's module to avoid option
            # definition collisions
            disabledModules = [ "${modulesPath}/programs/anyrun.nix" ];
          }
        )
        inputs.walker.homeManagerModules.default
        inputs.anyrun.homeManagerModules.default
        inputs.ags.homeManagerModules.default
        inputs.sops-nix.homeManagerModules.sops
        inputs.catppuccin.homeModules.catppuccin

        top.config.flake.modules.homeManager.programs-krita
        top.config.flake.modules.homeManager.programs-neovim
        # programs-eww intentionally not imported: converted, but kept unused
        # programs-wayland intentionally not imported: converted, but kept unused
        # programs-productivity intentionally not imported: converted, but kept unused (orphaned/empty)

        top.config.flake.modules.homeManager.programs-accounts
        top.config.flake.modules.homeManager.programs-browsers
        top.config.flake.modules.homeManager.programs-calendar
        top.config.flake.modules.homeManager.programs-chat
        top.config.flake.modules.homeManager.programs-eww-widgets
        top.config.flake.modules.homeManager.programs-niri
        top.config.flake.modules.homeManager.programs-pls
        top.config.flake.modules.homeManager.programs-desktop

        top.config.flake.modules.homeManager.programs-ai-claude-mit
        top.config.flake.modules.homeManager.programs-ai-pi-local
        # top.config.flake.modules.homeManager.programs-ai-unsloth
        top.config.flake.modules.homeManager.programs-aliases
        top.config.flake.modules.homeManager.programs-git
        top.config.flake.modules.homeManager.programs-tmux
        top.config.flake.modules.homeManager.programs-vscode
        top.config.flake.modules.homeManager.programs-wezterm
        top.config.flake.modules.homeManager.programs-yazi
        top.config.flake.modules.homeManager.programs-zsh
        top.config.flake.modules.homeManager.programs-devtools

        top.config.flake.modules.homeManager.programs-media
        top.config.flake.modules.homeManager.theme-rofi

        ../../home/nathan/home.nix
        # Declares `programs.pi-coding-agent`, which the pinned home-manager
        # (26.05) does not ship - see the header in that file.
        ../../home/vendor/pi-coding-agent.nix
        ../../themes/stylix.nix
      ];

      news.display = "silent";

      home.packages = with inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}; [
        nix-alien
      ];

      sops = {
        age.keyFile = "/home/nathan/.config/sops/age/keys.txt";
        defaultSopsFile = ../../secrets/secrets.yaml;
        secrets."llms/anthropic/api_key" = { };
        secrets."llms/openrouter/api_key" = { };
      };

      xdg.userDirs.setSessionVariables = false;
    };
}
