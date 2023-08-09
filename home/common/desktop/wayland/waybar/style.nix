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

  window#waybar > .horizontal {   
    margin: 8px 8px 0 8px;
    color: @lavender;
    background-color: @base; 
    font-weight: normal;
    border: 0;
    border-radius: ${border-radius};
    padding: 0;
  }

  button {
    /* Use box-shadow instead of border so the text isn't offset */
    box-shadow: inset 0 -3px @crust;
    /* Avoid rounded borders under each button name */
    border: none;
    border-radius: 0;
  }

  /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */

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
  #tray,
  #window,
  #taskbar,
  #custom-powermenu {
    padding: 5px 10px;
  }

  #workspaces {
    padding: 0;
    margin-left: ${border-radius};
  }

  #workspaces button {
    padding: 0 8px;
    color: @surface2;
    margin: 0;
    -gtk-icon-transform: scale(1.5);
  }

  #workspaces button.active {
    color: @lavender;

    /* Use box-shadow instead of border so the text isn't offset */
    box-shadow: inset 0 -3px @lavender;
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
