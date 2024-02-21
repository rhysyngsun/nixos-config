{ pkgs, ... }:
{
  environment.sessionVariables = {
    CLUTTER_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    MOZ_ENABLE_WAYLAND = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_BACKEND = "vulkan";
    GDK_BACKEND = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    # QT_QPA_PLATFORMTHEME = "gtk2";
    # Fix for some Java AWT applications (e.g. Android Studio),
    # use this if they aren't displayed properly:
    _JAVA_AWT_WM_NONREPARENTING = "1";
    # Better Wayland support for Electron-based apps
    # https://discourse.nixos.org/t/partly-overriding-a-desktop-entry/20743/2?u=ziedak
    NIXOS_OZONE_WL = "1";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };
}
