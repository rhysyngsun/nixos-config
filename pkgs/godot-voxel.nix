{
  alsa-lib,
  dbus,
  fetchzip,
  fontconfig,
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
  speechd-minimal,
  stdenv,
  udev,
  vulkan-loader,
  wayland,
  withDbus ? true,
  withFontconfig ? true,
  withPulseaudio ? true,
  withSpeechd ? true,
  withUdev ? true,
  # Wayland in Godot requires X11 until upstream fix is merged
  # https://github.com/godotengine/godot/pull/73504
  withWayland ? true,
  withX11 ? true,
}:
let
  pname = "godot-voxel";
  version = "1.5";
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
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchzip {
    url = "https://github.com/Zylann/godot_voxel/releases/download/v${version}/godot.linuxbsd.editor.x86_64.zip";
    hash = "sha256-qpAe3Ps9jrJED4f30zpGF7yNd13OI37Ymu0RSWQ3UOY=";
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
