{ pkgs, config, ... }:
{
  xsession.windowManager.bspwm = {
    # enable = true;
    extraConfigEarly = ''
    #! /bin/sh
    #

    killall sxhkd

    # Set the number of workspaces
    bspc monitor -d 1 2 3 4 5 6

    sxhkd &

    # Window configurations
    bspc config border_width         0
    bspc config window_gap           8
    bspc config split_ratio          0.5
    bspc config borderless_monocle   true
    bspc config gapless_monocle      true

    # Padding outside of the window
    bspc config top_padding            0
    bspc config bottom_padding         0
    bspc config left_padding           0
    bspc config right_padding          0

    # Move floating windows
    bspc config pointer_action1 move

    # Resize floating windows
    bspc config pointer_action2 resize_side
    bspc config pointer_action2 resize_corner

    # Set background and top bar
    ${config.xdg.configHome}/polybar/launch.sh

    sleep .25

    # Desktop 1
    # ------------------------------------------------------
    bspc rule -a wtf-dashboard desktop='^1' follow=on

    ${config.programs.alacritty.package}/bin/alacritty --title=wtf-dashboard -e ${pkgs.wtf}/bin/wtfutil &

    sleep .25

    # Desktop 2
    # ------------------------------------------------------
    bspc rule -a Alacritty desktop='^2' follow=on

    ${config.programs.alacritty.package}/bin/alacritty &

    sleep .25

    # Desktop 3
    # ------------------------------------------------------
    bspc rule -a firefox desktop='^3' follow=on

    ${config.programs.firefox.package}/bin/firefox &

    sleep .25

    # Desktop 4
    # ------------------------------------------------------
    bspc rule -a Alacritty:alacritty:xplr desktop='^4' follow=on

    ${config.programs.alacritty.package}/bin/alacritty -e ${pkgs.xplr}/bin/xplr &

    sleep .25

    # Desktop 5
    # ------------------------------------------------------
    bspc rule -a Code:code desktop='^5' follow=on
    ${pkgs.vscode}/bin/code &
    
    '';
  };
}
