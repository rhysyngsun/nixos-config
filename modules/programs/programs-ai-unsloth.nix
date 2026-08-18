{ ... }:
{
  flake.modules.homeManager.programs-ai-unsloth =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.unsloth-studio ];

      # Unsloth is a Tauri app, and webkitgtk's DMA-BUF renderer paints a blank
      # window under the proprietary NVIDIA driver lilith runs. Shadowing the
      # bundled entry (XDG_DATA_HOME wins over the profile) scopes the
      # workaround to this app instead of exporting it into the session, where
      # it would slow every other webkit client down.
      xdg.desktopEntries.Unsloth = {
        name = "Unsloth";
        comment = "Unsloth Desktop App";
        exec = "env WEBKIT_DISABLE_DMABUF_RENDERER=1 ${pkgs.unsloth-studio}/bin/unsloth-studio %u";
        icon = "unsloth-studio";
        terminal = false;
        type = "Application";
        settings = {
          StartupWMClass = "unsloth-studio";
          MimeType = "x-scheme-handler/unsloth;";
        };
      };
    };
}
