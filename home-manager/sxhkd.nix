{ pkgs, config, ... }:

{
  services.sxhkd = {
    enable = true;
    keybindings = {
      # Close window
      "alt + F4" = ''
        bspc node --close
      '';

      # Make split ratios equal
      "super + equal" = ''
        bspc node @/ --equalize
      '';

      # Make split ratios balanced
      "super + minus" = ''
        bspc node @/ --balance
      '';
      
      # Toogle tiling of window
      "super + d" = ''
        bspc query --nodes -n focused.tiled && state=floating || state=tiled; \
        bspc node --state \~$state
      '';

      # Toggle fullscreen of window
      "super + f" = ''
        bspc node --state \~fullscreen
      '';

      # Swap the current node and the biggest window
      "super + g" = ''
        bspc node -s biggest.window
      '';

      # Swap the current node and the smallest window
      "super + shift + g" = ''
        bspc node -s biggest.window
      '';

      # Alternate between the tiled and monocle layout
      "super + m" = ''
        bspc desktop -l next
      '';

      # Move between windows in monocle layout
      "super + {_, alt + }m" = ''
        bspc node -f {next, prev}.local.!hidden.window
      '';

      # Focus the node in the given direction
      "super + {_,shift + }{h,j,k,l}" = ''
        bspc node -{f,s} {west,south,north,east}
      '';

      # Focus left/right occupied desktop
      "super + {Left,Right}" = ''
        bspc desktop --focus {prev,next}.occupied
      '';

      # Focus left/right occupied desktop
      "super + {Up,Down}" = ''
        bspc desktop --focus {prev,next}.occupied
      '';

      # Focus left/right desktop
      "ctrl + alt + {Left,Right}" = ''
        bspc desktop --focus {prev,next}
      '';

      # Focus left/right desktop
      "ctrl + alt + {Up, Down}" = ''
        bspc desktop --focus {prev,next}
      '';

      # Focus the older or newer node in the focus history
      "super + {o,i}" = ''
        bspc wm -h off; \
        bspc node {older,newer} -f; \
        bspc wm -h on
      '';

      # Focus or send to the given desktop
      "super + {_,shift + }{1-9,0}" = ''
        bspc {desktop -f,node -d} '^{1-9,10}'
      '';

      # Cancel the preselect
      # For context on syntax: https://github.com/baskerville/bspwm/issues/344
      "super + alt + {_,shift + }Escape" = ''
        bspc query -N -d | xargs -I id -n 1 bspc node id -p cancel
      '';

      # Preselect the direction
      "super + ctrl + {h,j,k,l}" = ''
        bspc node -p {west,south,north,east}
      '';

      # Cancel the preselect
      # For context on syntax: https://github.com/baskerville/bspwm/issues/344
      "super + ctrl + {_,shift + }Escape" = ''
        bspc query -N -d | xargs -I id -n 1 bspc node id -p cancel
      '';

      # Set the node flags
      "super + ctrl + {m,x,s,p}" = ''
        bspc node -g {marked,locked,sticky,private}
      '';

      # Send the newest marked node to the newest preselected node
      "super + y" = ''
        bspc node newest.marked.local -n newest.!automatic.local
      '';

      # resize windows
      "super + alt + {h,j,k,l}" = ''
        {bspc node @parent/second -z left -20 0; \
        bspc node @parent/first -z right -20 0, \
        bspc node @parent/second -z top 0 +20; \
        bspc node @parent/first -z bottom 0 +20, \
        bspc node @parent/first -z bottom 0 -20; \
        bspc node @parent/second -z top 0 -20, \
        bspc node @parent/first -z right +20 0; \
        bspc node @parent/second -z left +20 0}
      '';

      # interactive resize mode - credit: DistroTube
      "super + s : {h,j,k,l}" = ''
        STEP=20; SELECTION={1,2,3,4}; \
        bspc node -z $(echo "left -$STEP 0,bottom 0 $STEP,top 0 -$STEP,right $STEP 0" | cut -d',' -f$SELECTION) || \
        bspc node -z $(echo "right -$STEP 0,top 0 $STEP,bottom 0 -$STEP,left $STEP 0" | cut -d',' -f$SELECTION)
      '';

      # Program launcher
      "super + @space" = ''
        rofi -config -no-lazy-grab -show drun -modi drun -theme ~/.config/polybar/scripts/rofi/launcher.rasi
      '';

      # Terminal emulator
      "super + Return" = ''
        bspc rule -a Alacritty -o state=floating rectangle=1024x768x0x0 center=true && ${config.programs.alacritty.package}/bin/alacritty
      '';

      # Terminal emulator
      "super + ctrl + Return" = ''
        ${config.programs.alacritty.package}/bin/alacritty
      '';

      # Jump to workspaces
      "super + t" = ''
        bspc desktop --focus ^2
      '';
      "super + b" = ''
        bspc desktop --focus ^1
      '';
      "super + w" = ''
        bspc desktop --focus ^4
      '';
      "super + Tab" = ''
        bspc {node,desktop} -f last
      '';

      # Window switcher:   
      "alt + Tab" = ''
        rofi -show window -show-icons
      '';

      # Web browser
      "ctrl + alt + Return" = ''
        ${config.programs.firefox.package}/bin/firefox
      '';

      # File browser at home dir
      "super + shift + @space" = ''
        ${pkgs.xplr}/bin/xplr
      '';

      # Take a screenshot with PrintSc
      "Print" = ''
        flameshot gui
      '';

      # Lock the screen
      "ctrl + alt + BackSpace" = ''
          betterlockscreen -l blur
      '';

      # Audio controls for + volume
      "XF86AudioRaiseVolume" = ''
        pactl set-sink-volume @DEFAULT_SINK@ +5%
      '';

      # Audio controls for - volume
      "XF86AudioLowerVolume" = ''
        pactl set-sink-volume @DEFAULT_SINK@ -5%
      '';

      # Audio controls for mute
      "XF86AudioMute" = ''
        pactl set-sink-mute @DEFAULT_SINK@ toggle
      '';
    };
  };
}

