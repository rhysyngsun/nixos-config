# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = import ../pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    hyprpaper = inputs.hyprpaper.packages.${final.system}.default;
    # waybar with Hyprland IPC support, allow workspace switching
    waybar = prev.waybar.overrideAttrs (oldAttrs: rec {
      mesonFlags = (oldAttrs.mesonFlags or [ ]) ++ [ "-Dexperimental=true" ];
      preConfigurePhases = (oldAttrs.preConfigurePhase or [ ]) ++ [ "hyprPhase" ];
      hyprPhase = ''
        sed -i 's/zext_workspace_handle_v1_activate(workspace_handle_);/const std::string command = "hyprctl dispatch workspace " + name_;\n\tsystem(command.c_str());/g' src/modules/wlr/workspace_manager.cpp
      '';
    });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
