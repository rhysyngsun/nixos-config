{
  pkgs,
  inputs,
  system,
  ...
}:

{
  programs.anyrun = {
    enable = true;
    config = {
      plugins = with inputs.anyrun.packages.${system}; [
        applications
        kidex
        rink
        shell
        websearch
      ];

      y = { absolute = 50; };
      width = { fraction = 0.35; };
      hideIcons = false;
      ignoreExclusiveZones = true;
      layer = "overlay";
      hidePluginInfo = true;
      closeOnClick = true;
      showResultsImmediately = true;
      maxEntries = null;
    };

    extraCss = ''
      * {
        transition: 200ms ease;
        font-family: Font Awesome, FiraCode, FiraMono, Isoveka;
        font-size: 1.3rem;
        outline: none; 
        border: none;
        box-shadow: none;
        color: #cdd6f4;
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
