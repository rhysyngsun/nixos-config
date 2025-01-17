{ 
  alsa-lib,
  autoPatchelfHook,
  buildPackages,
  dbus,
  dotnet-sdk_6,
  dotnet-sdk_8,
  dotnetCorePackages,
  fetchzip,
  fontconfig,
  installShellFiles,
  lib,
  libdecor,
  libGL,
  libpulseaudio,
  libX11,
  libXcursor,
  libXext,
  libXfixes,
  libXi,
  libXinerama,
  libxkbcommon,
  libXrandr,
  libXrender,
  makeWrapper,
  pkg-config,
  scons,
  speechd-minimal,
  stdenv,
  testers,
  udev,
  vulkan-loader,
  wayland,
  wayland-scanner,
  withDbus ? true,
  withFontconfig ? true,
  withMono ? false,
  withPlatform ? "linuxbsd",
  withPrecision ? "single",
  withPulseaudio ? true,
  withSpeechd ? true,
  withTarget ? "editor",
  withTouch ? true,
  withUdev ? true,
  # Wayland in Godot requires X11 until upstream fix is merged
  # https://github.com/godotengine/godot/pull/73504
  withWayland ? true,
  withX11 ? true,
}:
let 
  pname = "godot-voxel";
  version = "1.3.0";
  libs = 
      [
        alsa-lib
        libGL
        vulkan-loader
      ]
      ++ lib.optionals withX11 [
        libX11
        libXcursor
        libXext
        libXfixes
        libXi
        libXinerama
        libxkbcommon
        libXrandr
        libXrender
      ]
      ++ lib.optionals withWayland [
        libdecor
        wayland
      ]
      ++ lib.optionals withDbus [
        dbus
        dbus.lib
      ]
      ++ lib.optionals withFontconfig [
        fontconfig
        fontconfig.lib
      ]
      ++ lib.optionals withPulseaudio [ libpulseaudio ]
      ++ lib.optionals withSpeechd [ speechd-minimal ]
      ++ lib.optionals withUdev [ udev ];
in stdenv.mkDerivation {
    inherit pname version;

    src = fetchzip {
      url = "https://github.com/Zylann/godot_voxel/releases/download/v${version}/godot.linuxbsd.editor.x86_64.zip";
      hash = "sha256-4cfuBrrWE0RAUBiwHIHww6GA8OL3Bqqb6+cBTPFG6G0=";
    };

    nativeBuildInputs = [ makeWrapper ];

    installPhase = ''
      install -m755 -D godot.linuxbsd.editor.x86_64 $out/bin/godot-voxel
    '';

    postFixup = ''
      wrapProgram $out/bin/godot-voxel \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath libs}
    '';
    
  }
