{ inputs, ... }:
let
  border-radius = "6px";
  catppuccin-css = inputs.catppuccin-waybar + "/themes/mocha.css";
in
''
  /* catppucin-waybar ************************************************/
  @import "${catppuccin-css}";

  /* custom css ******************************************************/

  * {
    /* `otf-font-awesome` is required to be installed for icons */
    font-family: Font Awesome, FiraCode, FiraMono, Isoveka;
    font-size: 14px;
  }

  window#waybar {
    background-color: transparent;
    color: transparent;
    transition-property: background-color;
    transition-duration: .5s;
  }

  button {
    /* Use box-shadow instead of border so the text isn't offset */
    box-shadow: inset 0 -3px transparent;
    /* Avoid rounded borders under each button name */
    border: none;
    border-radius: 0;
  }

  /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */

  #workspaces button {
    padding: 0 8px; 
    background-color: @base;
    color: @lavender;
    margin: 0;
    -gtk-icon-transform: scale(1.5);
  }

  #workspaces button.active {
    background-color: @crust;
  }

  #clock,
  #battery,
  #cpu,
  #memory,
  #temperature,
  #network,
  #pulseaudio,
  #keyboard-state,
  #mpd,
  #disk,
  #workspaces,
  #tray,
  #window,
  #custom-notification,
  #taskbar,
  #custom-powermenu {
    padding: 0 10px;
    margin: 8px 0 0 0;
    color: @lavender;
    background-color: @base; 
    font-weight: normal;
    border-top: 1px solid @surface2;
    border-bottom: 1px solid @surface2;
  }

  #workspaces {
    background-color: @base;
    margin-left: 8px;
    margin-top: 8px;
    margin-right: 0;
    padding: 0 10px;
    border-radius: 0;
    border-right: 0; 
  }

  #battery, #custom-powermenu, #taskbar, #tray {
    border-top-right-radius: ${border-radius}; 
    border-bottom-right-radius: ${border-radius};
    border-right: 1px solid @surface2;
  }

  #clock, #cpu, #workspaces, #custom-powermenu {
    border-top-left-radius: ${border-radius}; 
    border-bottom-left-radius: ${border-radius};
    border-left: 1px solid @surface2;
  }

  #custom-powermenu {
    margin-right: 8px;
    margin-left: 8px;
  }

  @keyframes blink {
    to {
      background-color: #ffffff;
      color: #000000;
    }
  }

  label:focus {
    background-color: #000000;
  }

  #network.disconnected {
      background-color: @base;
  }

  #pulseaudio.muted {
      background-color: @base;
  }

  #temperature.critical {
      background-color: @red;
  }

  #keyboard-state {
      margin-top: 8px;
      padding: 0 0px;
      min-width: 16px;
  }

  #keyboard-state > label {
      padding: 0 5px;
  }

  #keyboard-state > label.locked {
      background: rgba(0, 0, 0, 0.2);
  }
''
