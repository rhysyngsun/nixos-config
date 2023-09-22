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
    ./services.nix
    ./swww.nix
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

      xwayland {
        force_zero_scaling = true
      }

      exec-once=${./scripts/xdg-portals-fix.sh}
      exec-once=systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK
      exec-once=hash dbus-update-activation-environment 2>/dev/null && dbus-update-activation-environment --systemd DISPLAY WAYLAND_ DISPLAY SWAYSOCK

      exec-once=xprop -root -f _XWAYLAND_GLOBAL_OUTPUT_SCALE 32c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE 2
      exec-once=export GDK_SCALE=2; export XCURSOR_SIZE=32; export GTK_THEME="Catppuccin-Mocha-Compact-Lavender-Dark"
      exec-once=hyprctl setcursor "Catppuccin-Mocha-Lavender" 32
      exec-once=env RUST_BACKTRACE=1 RUST_LOG=swayr=debug swayrd > /tmp/swayrd.log 2>&1
      exec-once=nm-applet -indicator

      source=${inputs.catppuccin-hyprland}/themes/mocha.conf

      general {
        gaps_in = 4
        gaps_out = 8
        resize_on_border = yes

        col.active_border = 0x00000000
        col.inactive_border = 0x00000000
      }

      input {
        kb_layout = us
        numlock_by_default = yes
        follow_mouse = 1
      }

      gestures {
        workspace_swipe = on
      }

      decoration {
        rounding = 5px

        blur {
          size = 2
          passes = 1
          new_optimizations = yes
        }

        active_opacity = 1.0
        inactive_opacity = 0.6

        drop_shadow = off

        col.shadow = 0x00000000
      }

      dwindle {
        preserve_split = on
      }

      misc {
        key_press_enables_dpms = true
        mouse_move_enables_dpms = true
        vrr = 1

        groupbar_gradients = no
        groupbar_text_color = 0x111111bff
      }

      workspace = 1, monitor:eDP-1
      workspace = 3, monitor:eDP-1
      workspace = 5, monitor:eDP-1
      workspace = 7, monitor:eDP-1
      workspace = 9, monitor:eDP-1

      workspace = 2, monitor:HDMI-A-1
      workspace = 4, monitor:HDMI-A-1
      workspace = 6, monitor:HDMI-A-1
      workspace = 8, monitor:HDMI-A-1
      workspace = 10, monitor:HDMI-A-1
    
      windowrulev2 = tile, class:^(Spotify)$

      windowrulev2 = noanim, title: ^(wlogout)$
      windowrulev2 = animation fadeIn, title: ^(wlogout)$
      windowrulev2 = float, title: ^(wlogout)$
      windowrulev2 = fullscreen, title: ^(wlogout)$
      
      windowrulev2 = noanim,class:^(flameshot)$
      windowrulev2 = float,class:^(flameshot)$
      windowrulev2 = move 0 0,class:^(flameshot)$

      windowrulev2 = tile,class:title:^(Zoom.*)$
      windowrulev2 = opacity 1.0 override 1.0 override,title:^(Zoom.*)$
      windowrulev2 = nodim,class:title:^(Zoom.*)$

      windowrulev2 = float,class:^(com.obsproject.Studio)$
      windowrulev2 = bordercolor $float_border_color,class:^(com.obsproject.Studio)$
      windowrulev2 = size $float_default_width $float_default_height,class:^(com.obsproject.Studio)$
      windowrulev2 = center,class:^(com.obsproject.Studio)$

      windowrulev2 = nofullscreenrequest, class:^(firefox)$, title:^(Picture-in-Picture)$
      windowrulev2 = nomaximizerequest, class:^(firefox)$, title:^(Picture-in-Picture)$
      windowrulev2 = nodim, class:^(firefox)$, title:^(Picture-in-Picture)$
      windowrulev2 = opacity 1.0 override 1.0 override, class:^(firefox)$, title:^(Picture-in-Picture)$

      windowrulev2 = opacity 1.0 override 1.0 override, class:^(krita)$

      windowrulev2 = forcergbx, class:^(blender)$

      layerrule = blur, ^(gtk-layer-shell|wlogout)$
      layerrule = ignorezero, ^(gtk-layer-shell|wlogout)$

      layerrule = blur, ^(gtk-layer-shell|anyrun)$
      layerrule = ignorezero, ^(gtk-layer-shell|anyrun)$

      windowrule = float,title:^(Open)$
      windowrule = float,title:^(Choose Files)$
      windowrule = float,title:^(Save As)$
      windowrule = float,title:^(Confirm to replace files)$
      windowrule = float,title:^(File Operation Progress)$
    
      exec-once = firefox & alacritty & slack

      bind=$mainMod, Q, killactive

      bind=$mainMod,TAB,exec,${cmds.swayr} switch-window
      bind=$mainMod,W,exec,${cmds.swayr} steal-window

      # screen lock on close or SUPER+L
      bindl=,switch:Lid Switch,exec,${cmds.swaylock}
      bind=$mainMod,L,exec,${cmds.swaylock}

      bind=$mainMod,RETURN,exec,alacritty -e tmux
      bind=$mainMod,B,exec,firefox
      bind=$mainMod,D,exec,anyrun

      bind=$mainMod,F,fullscreen,1
      bind=$mainMod SHIFT,F,fullscreen,0
      bind=$mainMod, V, togglefloating
      bind=$mainMod, P, pin

      bind=$mainMod, O, toggleopaque

      bind=$mainMod,G,togglegroup
      bind=$mainMod,apostrophe,changegroupactive,f
      bind=$mainMod SHIFT,apostrophe,changegroupactive,b

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
      bind=,XF86AudioRaiseVolume,exec,pamixer -i 5 --allow-boost --set-limit 200
      bind=,XF86AudioLowerVolume,exec,pamixer -d 5
      bind=,XF86AudioMute,exec,pamixer -t
      bind=SHIFT,XF86AudioMute,exec,pamixer --default-source -t
      bind=,XF86AudioPlay,exec,playerctl play-pause
      bind=,XF86AudioStop,exec,playerclt pause
      bind=,XF86AudioNext,exec,playerctl next
      bind=,XF86AudioPrev,exec,playerctl previous

      bind=,Print, exec, flameshot gui
    '';

    plugins = [
      # pkgs.hy3
    ];

    xwayland = {
      enable = true;
    };
  };
}

