{ config, pkgs, lib, ... }:
let
  flameshot = pkgs.flameshot.overrideAttrs (_: {
    src = pkgs.fetchFromGitHub {
      owner = "flameshot-org";
      repo = "flameshot";
      rev = "3ededae5745761d23907d65bbaebb283f6f8e3f2";
      sha256 = "sha256-4SMg63MndCctpfoOX3OQ1vPoLP/90l/KGLifyUzYD5g=";
    };
    cmakeFlags = [
      "-DUSE_WAYLAND_GRIM=1"
    ];
  });
  fmt = pkgs.formats.ini { };
  screenshotDir = "Pictures/Screenshots";
in
{
  home.packages = [ flameshot ];

  home.file."${screenshotDir}/.keep".text = "";

  xdg.configFile."flameshot/config.ini".source = (fmt.generate "config.ini" {
    General = {
      # Configure which buttons to show after drawing a selection
      # Not easy to set by hand
      # buttons=@Variant(\0\0\0\x7f\0\0\0\vQList<int>\0\0\0\0\x14\0\0\0\0\0\0\0\x1\0\0\0\x2\0\0\0\x3\0\0\0\x4\0\0\0\x5\0\0\0\x6\0\0\0\x12\0\0\0\xf\0\0\0\x13\0\0\0\a\0\0\0\b\0\0\0\t\0\0\0\x10\0\0\0\n\0\0\0\v\0\0\0\f\0\0\0\r\0\0\0\xe\0\0\0\x11)

      # List of colors for color picker
      # The colors are arranged counter-clockwise with the first being set to the right of the cursor
      # Colors are any valid hex code or W3C color name
      # "picker" adds a custom color picker
      # userColors=picker, #800000, #ff0000, #ffff00, #00ff00, #008000, #00ffff, #0000ff, #ff00ff, #800080
      # 
      # Image Save Path
      savePath = "${config.home.homeDirectory}/${screenshotDir}";
      # 
      # Whether the savePath is a fixed path (bool)
      # savePathFixed=false
      # 
      # Default file extension for screenshots
      # saveAsFileExtension=.png
      # 
      # Main UI color
      # Color is any valid hex code or W3C color name
      uiColor = "#1e1e2e";
      # 
      # Contrast UI color
      # Color is any valid hex code or W3C color name
      contrastUiColor = "#cdd6f4";
      # 
      # Last used color
      # Color is any valid hex code or W3C color name
      # drawColor=#ff0000
      # 
      # Show the help screen on startup (bool)
      # showHelp=true
      # 
      # Show the side panel button (bool)
      # showSidePanelButton=true
      # 
      # Ignore updates to versions less than this value
      # ignoreUpdateToVersion=
      # 
      # Show desktop notifications (bool)
      # showDesktopNotification=true
      # 
      # Filename pattern using C++ strftime formatting
      # filenamePattern=%F_%H-%M
      # 
      # Whether the tray icon is disabled (bool)
      # disabledTrayIcon=false
      # 
      # Automatically close daemon when it's not needed (not available on Windows)
      # autoCloseIdleDaemon=false
      # 
      # Allow multiple instances of `flameshot gui` to run at the same time
      # allowMultipleGuiInstances=false
      # 
      # Last used tool thickness (int)
      # drawThickness=1
      # 
      # Keep the App Launcher open after selecting an app (bool)
      # keepOpenAppLauncher=false
      # 
      # Launch at startup (bool)
      # startupLaunch=true
      # 
      # Opacity of area outside selection (int in range 0-255)
      # contrastOpacity=190
      # 
      # Save image after copy (bool)
      # saveAfterCopy=false
      # 
      # Copy path to image after save (bool)
      # copyPathAfterSave=false
      # 
      # On successful upload, close the dialog and copy URL to clipboard.
      # copyAndCloseAfterUpload=true
      # 
      # Anti-aliasing image when zoom the pinned image (bool)
      # antialiasingPinZoom=true
      # 
      # Use JPG format instead of PNG (bool)
      # useJpgForClipboard=false
      # 
      # Upload to imgur without confirmation (bool)
      uploadWithoutConfirmation = false;
    };
  });
}
