{
  pkgs,
  ...
}:
let
  inherit (pkgs) anyrun;
in
{
  home.packages = [anyrun];

  xdg.configFile = {
    "anyrun/config.ron".text = ''
      Config(
        // `width` and `vertical_offset` use an enum for the value it can be either:
        // Absolute(n): The absolute value in pixels
        // Fraction(n): A fraction of the width or height of the full screen (depends on exclusive zones and the settings related to them) window respectively

        // How wide the input box and results are.
        width: Fraction(0.35),

        // Where Anyrun is located on the screen: Top, Center
        position: Top,

        // How much the runner is shifted vertically
        vertical_offset: Absolute(10),

        // Hide match and plugin info icons
        hide_icons: false,

        // ignore exclusive zones, f.e. Waybar
        ignore_exclusive_zones: true,

        // Layer shell layer: Background, Bottom, Top, Overlay
        layer: Overlay,

        // Hide the plugin info panel
        hide_plugin_info: true,

        // Close window when a click outside the main box is received
        close_on_click: true,

        // Show search results immediately when Anyrun starts
        show_results_immediately: true,

        // Limit amount of entries shown in total
        max_entries: None,

        // List of plugins to be loaded by default, can be specified with a relative path to be loaded from the
        // `<anyrun config dir>/plugins` directory or with an absolute path to just load the file the path points to.
        plugins: [
          "${anyrun}/lib/libapplications.so",
          "${anyrun}/lib/librink.so",
          "${anyrun}/lib/libshell.so",
        ],
      )
    '';
    "anyrun/style.css".text = ''
      * {
        transition: 200ms ease;
        font-family: Font Awesome, FiraCode, FiraMono, Isoveka;
        font-size: 1.3rem;
        outline: none; 
        border: none;
        box-shadow: none;
      }
      

      #window {
        background: rgba(147, 153, 178, 0.3);
      }

      #match,
      #entry,
      #plugin,
      #main {
        background: transparent;
      }

      #match:selected {
        background: rgba(203, 166, 247, 0.7);
      }

      #match {
        padding: 3px;
        border-radius: 5px;
      }

      #entry {
        border: 1px solid #585b70;
      }

      box#main {
        background: #1e1e2e;
        border-radius: 5px;
        padding: 8px;
        box-shadow: 0px 0px 3px 0px rgba(30, 30, 46, 0.7);
      }
    '';

  };
}