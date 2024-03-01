{ config, pkgs, lib, inputs, ... }:
with lib;
let
  cmds = {
    swaylock = "${pkgs.swaylock-effects}/bin/swaylock";
    swayr = "${pkgs.swayr}/bin/swayr";
    terminal = "${config.programs.wezterm.package}/bin/wezterm start --always-new-process";
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
    systemd.enable = true;

    plugins = [
      # inputs.hycov.packages.${pkgs.system}.hycov
    ];

    extraConfig = ''
      $mod = SUPER

      # See https://wiki.hyprland.org/Configuring/Monitors/
      monitor=,preferred,auto,auto

      xwayland {
        force_zero_scaling = true
      }

      # env = GDK_SCALE,2
      env = XCURSOR_SIZE,32
      env = XCURSOR_THEME,Catppuccin-Mocha-Lavender
      env = GTK_THEME,Catppuccin-Mocha-Compact-Lavender-Dark

      exec-once=pkill eww && eww daemon
      exec-once=${./scripts/xdg-portals-fix.sh}
      exec-once=systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK
      exec-once=hash dbus-update-activation-environment 2>/dev/null && dbus-update-activation-environment --systemd DISPLAY WAYLAND_ DISPLAY SWAYSOCK

      exec-once=hyprctl setcursor "Catppuccin-Mocha-Lavender" 32
      exec-once=env RUST_BACKTRACE=1 RUST_LOG=swayr=debug swayrd > /tmp/swayrd.log 2>&1
      exec-once=nm-applet -indicator

      source=${inputs.catppuccin-hyprland}/themes/mocha.conf

      debug {
        disable_logs = false
        enable_stdout_logs = true
        suppress_errors = true
      }

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
        inactive_opacity = 0.3

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

      # plugin {
      #   hycov {
      #     overview_gappo = 60 # gaps width from screen edge
      #     overview_gappi = 24 # gaps width from clients
      #     enable_hotarea = 1 # enable mouse cursor hotarea, when cursor enter hotarea, it will toggle overview    
      #     hotarea_monitor = all # monitor name which hotarea is in, default is all
      #     hotarea_pos = 1 # position of hotarea (1: bottom left, 2: bottom right, 3: top left, 4: top right)
      #     hotarea_size = 10 # hotarea size, 10x10
      #     swipe_fingers = 4 # finger number of gesture,move any directory
      #     move_focus_distance = 100 # distance for movefocus,only can use 3 finger to move 
      #     enable_gesture = 0 # enable gesture
      #     auto_exit = 1 # enable auto exit when no client in overview
      #     auto_fullscreen = 0 # auto make active window maximize after exit overview
      #     only_active_workspace = 0 # only overview the active workspace
      #     only_active_monitor = 0 # only overview the active monitor
      #     enable_alt_release_exit = 0 # alt swith mode arg,see readme for detail
      #     alt_replace_key = Alt_L # alt swith mode arg,see readme for detail
      #     alt_toggle_auto_next = 0 # auto focus next window when toggle overview in alt swith mode
      #     click_in_cursor = 1 # when click to jump,the target windwo is find by cursor, not the current foucus window.
      #     hight_of_titlebar = 0 # height deviation of title bar height
      #   }
      # }

      misc {
        disable_hyprland_logo = true
        disable_splash_rendering = true

        key_press_enables_dpms = true
        mouse_move_enables_dpms = true

        vrr = 1
      }

      
      # # bind key to toggle overview (normal)
      # bind = ALT,tab,hycov:toggleoverview

      # # bind key to toggle overview (force mode, not affected by `only_active_workspace` or `only_active_monitor`)
      # bind = ALT,grave,hycov:toggleoverview,forceall #grave key is the '~' key

      # # bind key to toggle overview (shows all windows in one monitor, not affected by `only_active_workspace` or `only_active_monitor`)
      # bind = ALT,g,hycov:toggleoverview,forceallinone 

      # # The key binding for directional switch mode.
      # # Calculate the window closest to the direction to switch focus.
      # # This keybind is applicable not only to the overview, but also to the general layout.
      # bind=ALT,left,hycov:movefocus,l
      # bind=ALT,right,hycov:movefocus,r
      # bind=ALT,up,hycov:movefocus,u
      # bind=ALT,down,hycov:movefocus,d

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

      # windowrulev2 = suppressevent maximize fullscreen, class:(firefox), title:(Picture-in-Picture)
      windowrulev2 = nodim, class:^(firefox)$, title:^(Picture-in-Picture)$
      windowrulev2 = opacity 1.0 override 1.0 override, class:^(firefox)$, title:^(Picture-in-Picture)$

      windowrulev2 = opacity 1.0 override 1.0 override, class:^(krita)$
      windowrulev2 = opacity 1.0 override 1.0 override, class:^(blender)$

      windowrulev2 = opacity 1.0 override 1.0 override, class:^(ueberzugpp.*)$
      # move it offscreen so there is no flash before it gets positioned
      windowrulev2 = move 200% 0, class:^(ueberzugpp.*)$
      windowrulev2 = noanim, class:^(ueberzugpp.*)$

      # make flameshot behave
      windowrulev2=move 0 0,title:^(flameshot)
      # windowrulev2=suppressevent fullscreen,title:^(flameshot)

      windowrulev2 = forcergbx, class:^(blender)$

      layerrule = blur, ^(gtk-layer-shell|wlogout)$
      layerrule = ignorezero, ^(gtk-layer-shell|wlogout)$

      layerrule = blur, ^(gtk-layer-shell|anyrun)$
      layerrule = ignorezero, ^(gtk-layer-shell|anyrun)$

      windowrule = float,title:^(Open|Choose Files|Save As|Confirm to replace files|File Operation Progress)$
      windowrule = opacity 1.0 override 1.0 override,title:^(Open|Choose Files|Save As|Confirm to replace files|File Operation Progress)$
    
      exec-once = firefox

      bind=$mod, Q, killactive

      bind=$mod,TAB,exec,${cmds.swayr} switch-window
      bind=$mod,W,exec,${cmds.swayr} steal-window

      # screen lock on close or SUPER+L
      bindl=,switch:Lid Switch,exec,${cmds.swaylock}
      bind=$mod,L,exec,${cmds.swaylock}

      bind=$mod,RETURN,exec,${cmds.terminal}
      bind=$mod,B,exec,firefox
      bind=$mod,D,exec,anyrun

      bind=$mod,F,fullscreen,1
      bind=$mod SHIFT,F,fullscreen,0
      bind=$mod, V, togglefloating
      bind=$mod, P, pin

      bind=$mod, O, toggleopaque

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

      bindm=$mod,mouse:272,movewindow

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

    xwayland = {
      enable = true;
    };
  };
}

