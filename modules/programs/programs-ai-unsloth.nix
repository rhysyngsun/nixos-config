{ ... }:
{
  flake.modules.homeManager.programs-ai-unsloth =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.unsloth-studio ];

      # No desktop-entry shadow and no env overrides here, on purpose. Two
      # things used to live in this module and both are gone:
      #
      # - WEBKIT_DISABLE_DMABUF_RENDERER=1, for webkitgtk painting a blank
      #   window under the proprietary NVIDIA driver. The app now applies that
      #   workaround itself: it detects "NVIDIA driver loaded (Wayland session)"
      #   and exports *that exact variable*, recording the choice in
      #   UNSLOTH_WEBKIT_RENDERER_WORKAROUND - verified by reading the
      #   environment of the child process it spawns. So the override is not
      #   just redundant, it is the same fix upstream now ships. Shadowing the
      #   store entry would also permanently hide any upstream change to its
      #   MimeType or StartupWMClass, which is why it is not kept
      #   speculatively. (0.1.800 picked WEBKIT_DMABUF_RENDERER_FORCE_SHM for
      #   the same job; upstream switched variables, so do not pin either name
      #   here.)
      #
      # - The cert and PATH fixes. Those belong to the AppImage's FHS sandbox,
      #   not to this host, so they live in `profile` in pkgs/unsloth-studio.nix
      #   where they also apply when the binary is run straight from a terminal.
    };
}
