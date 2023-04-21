{ config, pkgs, lib, inputs, ... }:
with lib;
let
  cmds = {
    swaylock = "${pkgs.swaylock-effects}/bin/swaylock";
    swayr = "${pkgs.swayr}/bin/swayr";
  };
in
{
  imports = [
    ./hyprpaper.nix
    ./services.nix
  ];

  home.packages = with pkgs; [
    grim
    wl-clipboard
    swaylock-effects
    inotify-tools
    swayr

    # swaynotificationcenter
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemdIntegration = true;
    extraConfig = ''
      $mainMod = SUPER

      # See https://wiki.hyprland.org/Configuring/Monitors/
      monitor=,preferred,auto,auto

      exec-once=systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK
      exec-once=hash dbus-update-activation-environment 2>/dev/null && dbus-update-activation-environment --systemd DISPLAY WAYLAND_ DISPLAY SWAYSOCK

      # exec-once=${./scripts/launch_waybar.sh}
      exec-once=${pkgs.hyprpaper}/bin/hyprpaper
      exec-once=xprop -root -f _XWAYLAND_GLOBAL_OUTPUT_SCALE 32c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE 2
      exec-once=export GDK_SCALE=2; export XCURSOR_SIZE=32; export GTK_THEME="Catppuccin-Mocha-Compact-Lavender-Dark"
      exec-once=hyprctl setcursor "Catppuccin-Mocha-Lavender" 32

      source=${inputs.catppuccin-hyprland}/themes/mocha.conf

      general {
        gaps_in = 4
        gaps_out = 8
        resize_on_border = yes

        col.active_border = 0xffb4befe
        col.inactive_border = 0xff11111b
      }

      input {
        kb_layout = us
    
        follow_mouse = 1
        touchpad = {
          # natural_scroll = no
        }
      }

      gestures {
        workspace_swipe = on
      }

      decoration {
        rounding = 3px
        blur = yes
        blur_size = 2
        blur_passes = 1
        blur_new_optimizations = on
      }

      dwindle {
        preserve_split = on
      }
    
      windowrulev2 = tile, class:^(Spotify)$
      # windowrulev2 = workspace 1, class:^(Alacritty)$
      # windowrulev2 = workspace 2, class:^(Slack|discord)$
      # windowrulev2 = workspace 3, class:^(Code)$
      # windowrulev2 = workspace 4, class:^(firefox)$
      windowrulev2 = opacity 0.9 0.9,class:^(firefox|Code|Slack|discord|Spotify)$
    
      exec-once = firefox & alacritty & slack

      bind=$mainMod, Q, killactive

      bind=$mainMod,TAB,exec,${cmds.swayr} "prev-window all-workspaces"
      bind=$mainMod SHIFT,TAB,exec,${cmds.swayr} "next-window all-workspaces"

      # screen lock on close or SUPER+L
      bindl=,switch:Lid Switch,exec,${cmds.swaylock}
      bind=$mainMod,L,exec,${cmds.swaylock}

      bind=$mainMod,RETURN,exec,${config.programs.alacritty.package}/bin/alacritty -e tmux
      bind=$mainMod,B,exec,${config.programs.firefox.package}/bin/firefox
      bind=$mainMod,D,exec,${config.programs.rofi.package}/bin/rofi -show drun -show-icons
      # bind=$mainMod,N,exec,${pkgs.swaynotificationcenter}/bin/swaync-client -t

      bind=$mainMod,F,fullscreen,1
      bind=$mainMod SHIFT,F,fullscreen,0
      bind=$mainMod, V, togglefloating
      bind=$mainMod, P, pin

      bind=$mainMod,1,workspace,1
      bind=$mainMod,2,workspace,2
      bind=$mainMod,3,workspace,3
      bind=$mainMod,4,workspace,4
      bind=$mainMod,5,workspace,5
      bind=$mainMod,6,workspace,6
      bind=$mainMod,7,workspace,7
      bind=$mainMod,8,workspace,8
      bind=$mainMod,9,workspace,9
      bind=$mainMod,0,workspace,10

      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10

      bindm=ALT,mouse:272,movewindow

      # Bind volume controls
      bind=,XF86AudioRaiseVolume,exec,pactl set-sink-volume @DEFAULT_SINK@ +5%
      bind=,XF86AudioLowerVolume,exec,pactl set-sink-volume @DEFAULT_SINK@ -5%
      bind=,XF86AudioMute,exec,pactl set-sink-mute @DEFAULT_SINK@ toggle
      bind=SHIFT,XF86AudioMute,exec,pactl set-source-mute 1 toggle
      bind=,XF86AudioPlay,exec,playerctl play-pause
      bind=,XF86AudioStop,exec,playerclt pause
      bind=,XF86AudioNext,exec,playerctl next
      bind=,XF86AudioPrev,exec,playerctl previous

    '';
    xwayland = {
      enable = true;
      hidpi = true;
    };
  };
}
