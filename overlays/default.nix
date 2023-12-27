# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = import ../pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: let
    hyprctl = "${prev.hyprland}/bin/hyprctl";
  in {

    alacritty = prev.alacritty.overrideAttrs (oldAttrs: let
        version = "0.13-dev";
        src = prev.fetchFromGitHub {
          owner = "alacritty";
          repo = prev.alacritty.pname;
          rev = "d65357b213fb450c6ef4fa9d4fc09307cfe5f6fb";
          hash = "sha256-JuGLlZkfpmNpuGyvjZImEopdwQJ2789qzyI5FeVNBx4=";
        };
      in {
        inherit version src;
        cargoDeps = oldAttrs.cargoDeps.overrideAttrs (_: {
          inherit src;
          outputHash = "sha256-L5w82ajfbDkHNX9VEq9eev71SbftULjXYYHbYZiZmJE=";
        });
        postInstall =
          builtins.replaceStrings
            [ "extra/alacritty.man" "extra/alacritty-msg.man" "install -Dm 644 alacritty.yml $out/share/doc/alacritty.yml" ]
            [ "extra/alacritty.*" "extra/alacritty-msg.*" "" ]
            oldAttrs.postInstall;
      });
    
    devenv = inputs.devenv.packages.${final.system}.devenv;

    # waybar with Hyprland IPC support, allow workspace switching
    swaylock-effects = prev.swaylock-effects.overrideAttrs (oldAttrs: rec {
      version = "1.7.0.0";
      src = prev.fetchFromGitHub {
        owner = "jirutka";
        repo = "swaylock-effects";
        rev = "v${version}";
        hash = "sha256-cuFM+cbUmGfI1EZu7zOsQUj4rA4Uc4nUXcvIfttf9zE=";
      };
    });
    waybar = prev.waybar.overrideAttrs (oldAttrs: {
      mesonFlags = (oldAttrs.mesonFlags or [ ]) ++ [ "-Dexperimental=true" ];
      preConfigurePhases = (oldAttrs.preConfigurePhase or [ ]) ++ [ "hyprPhase" ];
      hyprPhase = ''
        sed -i 's|zext_workspace_handle_v1_activate(workspace_handle_);|const std::string command = "${hyprctl} dispatch workspace " + name_;\n\tsystem(command.c_str());|g' src/modules/wlr/workspace_manager.cpp
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
