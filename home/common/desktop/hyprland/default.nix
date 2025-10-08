{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;
{
  imports = [ ./services.nix ];

  home.packages = with pkgs; [
    grim
    wl-clipboard
    inotify-tools
    hyprpicker
    hyprshot
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;

    settings = {
      "$mainMod" = "SUPER";
      "$shiftMod" = "SUPER_SHIFT";
      "$altMod" = "SUPER_ALT";

      # apps
      "$eww" = "${config.programs.eww.package}/bin/eww";
      "$firefox" = "${config.programs.firefox.package}/bin/firefox";
      "$hyprlock" = "${config.programs.hyprlock.package}/bin/hyprlock";
      "$swayr" = "${pkgs.swayr}/bin/swayr";
      "$term" = "${config.programs.wezterm.package}/bin/wezterm start --always-new-process";

      monitor = [
        ",preferred,auto,auto"
      ];

      debug = {
        disable_logs = false;
        enable_stdout_logs = true;
        suppress_errors = true;
      };

      general = {
        gaps_in = 4;
        gaps_out = 8;
        resize_on_border = true;

        col.active_border = "rgba(00000000)";
        col.inactive_border = "rgba(00000000)";
      };

      input = {
        kb_layout = "us";
        numlock_by_default = true;
        follow_mouse = 1;
      };

      gestures = {
        workspace_swipe = true;
      };

      decoration = {
        rounding = 5;

        blur = {
          size = 2;
          passes = 1;
          new_optimizations = true;
        };

        active_opacity = 0.85;
        inactive_opacity = 0.3;

        drop_shadow = true;

        col.shadow = "rgba(00000000)";
      };

      group = {
        groupbar = {
          gradients = true;
          font_size = 10;
          text_color = "rgba(1e1e2eff)";
          col.active = "rgba(b4befeff) rgba(b4befeff)";
          col.inactive = "rgba(1e1e2eff) rgba(1e1e2eff)";
        };
      };

      dwindle = {
        preserve_split = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;

        key_press_enables_dpms = true;
        mouse_move_enables_dpms = true;

        vrr = 1;
      };

      xwayland = {
        force_zero_scaling = true;
      };

      exec-once = [
        "pkill $eww && $eww daemon"
        "systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK"
        "hash dbus-update-activation-environment 2>/dev/null && dbus-update-activation-environment --systemd DISPLAY WAYLAND_ DISPLAY SWAYSOCK"

        "hyprctl setcursor \"Catppuccin-Mocha-Lavender\" 32"
        "env RUST_BACKTRACE=1 RUST_LOG=swayr=debug swayrd > /tmp/swayrd.log 2>&1"
        "nm-applet -indicator"
        "$firefox"
        "$wezterm"
      ];

      workspace = builtins.genList (
          x:
          let
            ws = x + 1;
            monitor = if (lib.trivial.mod ws 2) == 1 then "eDP-1" else "HDMI-A-1";
          in
          "${toString ws}, workspace, monitor:${monitor}"
        ) 10;

      windowrulev2 = [

        "tile, class:^(Spotify)$"

        "noanim, title: ^(wlogout)$"
        "animation fadeIn, title: ^(wlogout)$"
        "float, title: ^(wlogout)$"
        "fullscreen, title: ^(wlogout)$"

        "noanim,class:^(flameshot)$"
        "float,class:^(flameshot)$"
        "move 0 0,class:^(flameshot)$"
        "move 0 0,title:^(flameshot)"

        "tile,class:title:^(Zoom.*)$"
        "opacity 1.0 override 1.0 override,title:^(Zoom.*)$"
        "nodim,class:title:^(Zoom.*)$"

        "float,class:^(com.obsproject.Studio)$"
        "bordercolor $float_border_color,class:^(com.obsproject.Studio)$"
        "size $float_default_width $float_default_height,class:^(com.obsproject.Studio)$"
        "center,class:^(com.obsproject.Studio)$"

        # "suppressevent maximize fullscreen, class:(firefox), title:(Picture-in-Picture)"
        "nodim, class:^(firefox)$, title:^(Picture-in-Picture)$"
        "opacity 1.0 override 1.0 override, class:^(firefox)$, title:^(Picture-in-Picture)$"

        "opacity 1.0 override 1.0 override, class:^(krita)$"
        "opacity 1.0 override 1.0 override, class:^(blender)$"

        "opacity 1.0 override 1.0 override, class:^(ueberzugpp.*)$"
        # move it offscreen so there is no flash before it gets positioned
        "move 200% 0, class:^(ueberzugpp.*)$"
        "noanim, class:^(ueberzugpp.*)$"

        "forcergbx, class:^(blender)$"
      ];
    };

    extraConfig = ''
      env = XCURSOR_SIZE,32
      env = XCURSOR_THEME,Catppuccin-Mocha-Lavender
      env = GTK_THEME,Catppuccin-Mocha-Compact-Lavender-Dark

      env = HYPRSHOT_DIR,~/Pictures/Screenshots

      source=${inputs.catppuccin-hyprland}/themes/mocha.conf

      layerrule = blur, ^(gtk-layer-shell|wlogout)$
      layerrule = ignorezero, ^(gtk-layer-shell|wlogout)$

      layerrule = blur, ^(gtk-layer-shell|anyrun)$
      layerrule = ignorezero, ^(gtk-layer-shell|anyrun)$

      windowrule = float,title:^(Open|Choose Files|Save As|Confirm to replace files|File Operation Progress)$
      windowrule = opacity 1.0 override 1.0 override,title:^(Open|Choose Files|Save As|Confirm to replace files|File Operation Progress)$

      bind=$mainMod, Q, killactive

      bind=$mainMod,TAB,exec,$swayr switch-window
      bind=$mainMod,W,exec,$swayr steal-window

      # screen lock on close or SUPER+L
      bind=$mainMod,L,exec,$hyprlock

      bind=$mainMod,RETURN,exec,$term
      bind=$mainMod,B,exec,firefox
      # bind=$mainMod,D,exec,anyrun
      bind=$mainMod,D,exec,nc -U /run/user/1000/walker/walker.sock

      bind=$mainMod,F,fullscreen,1
      bind=$mainMod SHIFT,F,fullscreen,0
      bind=$mainMod, V, togglefloating
      bind=$mainMod, P, pin

      bind=$mainMod, O, toggleopaque

      bind=$mainMod,apostrophe,changegroupactive,f
      bind=$mainMod SHIFT,apostrophe,changegroupactive,b

      bind=$mainMod, S, exec, hyprpicker -a -f hex

      bind=$mainMod, Space, overview:toggle

      ${builtins.concatStringsSep "\n" (
        builtins.genList (
          x:
          let
            ws =
              let
                c = (x + 1) / 10;
              in
              builtins.toString (x + 1 - (c * 10));
          in
          ''
            bind = $mainMod, ${ws}, workspace, ${toString (x + 1)}
            bind = $mainMod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}
          ''
        ) 10
      )}

      bindm=$mainMod,mouse:272,movewindow

      # Bind volume controls
      bind=,XF86AudioRaiseVolume,exec,pamixer -i 5 --allow-boost --set-limit 200
      bind=,XF86AudioLowerVolume,exec,pamixer -d 5 --allow-boost --set-limit 200
      bind=,XF86AudioMute,exec,pamixer -t
      bind=SHIFT,XF86AudioMute,exec,pamixer --default-source -t
      bind=,XF86AudioPlay,exec,playerctl play-pause
      bind=,XF86AudioStop,exec,playerclt pause
      bind=,XF86AudioNext,exec,playerctl next
      bind=,XF86AudioPrev,exec,playerctl previous

      # Screenshot a window
      bind = $mainMod, PRINT, exec, hyprshot -m window
      # Screenshot a monitor
      bind = , PRINT, exec, hyprshot -m output
      # Screenshot a region
      bind = $shiftMod, PRINT, exec, hyprshot -m region
    '';

    xwayland = {
      enable = true;
    };
  };
}
