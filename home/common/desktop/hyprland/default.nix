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
  ];

  home.packages = with pkgs; [
    grim
    wl-clipboard
    swaylock-effects
    inotify-tools
    swayr
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemdIntegration = true;
    extraConfig = ''
      $mod = SUPER

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
        rounding = 5

        blur {
          size = 2
          passes = 1
          new_optimizations = true
        }

        active_opacity = 0.85
        inactive_opacity = 0.6

        drop_shadow = off

        col.shadow = 0x00000000
      }

      group {
        groupbar {
          gradients = no
          font_size = 10
          text_color = rgba(1e1e2eff)
          col.active = rgba(b4befeff) rgba(b4befeff)
          col.inactive = rgba(1e1e2eff) rgba(1e1e2eff)
        }
      }

      dwindle {
        preserve_split = on
      }

      plugin {
        hy3 {
          no_gaps_when_only = true
          tabs = {
            rounding = 6
            col.active = rgba(b4befeff)
            col.inactive = rgba(1e1e2eff)
          }
        }
      }

      misc {
        disable_hyprland_logo = true
        disable_splash_rendering = true

        key_press_enables_dpms = true
        mouse_move_enables_dpms = true

        vrr = 1
      }

      ${builtins.concatStringsSep "\n" (builtins.genList (
        x: let
          ws = x + 1;
          monitor = if (lib.trivial.mod ws 2) == 1 then "eDP-1" else "HDMI-A-1";
        in ''
          workspace = ${toString ws}, workspace, monitor:${monitor}
        ''
      )
      10)}
    
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

      windowrulev2 = nofullscreenrequest, class:(firefox), title:(Picture-in-Picture)
      windowrulev2 = nomaximizerequest, class:(firefox), title:(Picture-in-Picture)
      windowrulev2 = nodim, class:^(firefox)$, title:^(Picture-in-Picture)$
      windowrulev2 = opacity 1.0 override 1.0 override, class:^(firefox)$, title:^(Picture-in-Picture)$

      windowrulev2 = opacity 1.0 override 1.0 override, class:^(krita)$

      # make flameshot behave
      windowrulev2=move 0 0,title:^(flameshot)
      windowrulev2=nofullscreenrequest,title:^(flameshot)

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

      bind=$mod, Q, killactive

      bind=$mod,TAB,exec,${cmds.swayr} switch-window
      bind=$mod,W,exec,${cmds.swayr} steal-window

      # screen lock on close or SUPER+L
      bindl=,switch:Lid Switch,exec,${cmds.swaylock}
      bind=$mod,L,exec,${cmds.swaylock}

      bind=$mod,RETURN,exec,alacritty -e tmux
      bind=$mod,B,exec,firefox
      bind=$mod,D,exec,anyrun

      bind=$mod,F,fullscreen,1
      bind=$mod SHIFT,F,fullscreen,0
      bind=$mod, V, togglefloating
      bind=$mod, P, pin

      bind=$mod, O, toggleopaque

      # bind=$mod,G,hy3:makegroup,tab
      bind=$mod,apostrophe,changegroupactive,f
      bind=$mod SHIFT,apostrophe,changegroupactive,b

      ${builtins.concatStringsSep "\n" (builtins.genList (
        x: let
          ws = let
            c = (x + 1) / 10;
          in
            builtins.toString (x + 1 - (c * 10));
        in ''
          bind = $mod, ${ws}, workspace, ${toString (x + 1)}
          bind = $mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}
        ''
      )
      10)}

      bindm=ALT,mouse:272,movewindow

      # Bind volume controls
      bind=,XF86AudioRaiseVolume,exec,pamixer -i 5 --allow-boost --set-limit 200
      bind=,XF86AudioLowerVolume,exec,pamixer -d 5 --allow-boost --set-limit 200
      bind=,XF86AudioMute,exec,pamixer -t
      bind=SHIFT,XF86AudioMute,exec,pamixer --default-source -t
      bind=,XF86AudioPlay,exec,playerctl play-pause
      bind=,XF86AudioStop,exec,playerclt pause
      bind=,XF86AudioNext,exec,playerctl next
      bind=,XF86AudioPrev,exec,playerctl previous

      bind=,Print, exec, flameshot gui
      
    '';

    plugins = [
      # inputs.hy3.packages.${pkgs.system}.hy3
    ];

    xwayland = {
      enable = true;
    };
  };
}

