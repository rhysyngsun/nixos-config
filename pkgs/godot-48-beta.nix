{
  source,
  alsa-lib,
  dbus,
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
  unzip,
  vulkan-loader,
  wayland,
}:
let
  # Same runtime closure the prebuilt editor expects as pkgs/godot-voxel.nix -
  # both are official upstream binaries, not built here, so neither can have
  # its library paths patched in at link time.
  libs = [
    alsa-lib
    dbus
    dbus.lib
    fontconfig
    fontconfig.lib
    libdecor
    libGL
    libpulseaudio
    libX11
    libXcursor
    libXext
    libXfixes
    libXi
    libXinerama
    libxkbcommon
    libXrandr
    libXrender
    speechd-minimal
    udev
    vulkan-loader
    wayland
  ];

  # Upstream names the binary after the release it was cut from, so the one
  # file in the zip moves with every `src.manual` bump in nvfetcher.toml.
  binary = "Godot_v${source.version}_linux.x86_64";

  # Deliberately not `godot`/`godot4`: nixpkgs' godot_4_7 is installed into the
  # same profile and owns those names.
  exeName = "godot-48-beta";
in
stdenv.mkDerivation {
  inherit (source) src pname version;

  # The release zip holds the bare editor binary with no enclosing directory,
  # so the usual single-root sourceRoot detection has nothing to find.
  sourceRoot = ".";

  nativeBuildInputs = [
    makeWrapper
    unzip
  ];

  installPhase = ''
    runHook preInstall

    install -m755 -D ${binary} $out/bin/${exeName}

    install -m644 -D /dev/stdin $out/share/applications/org.godotengine.Godot48Beta.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Godot Engine 4.8 (beta)
    GenericName=Libre game engine
    Comment=Multi-platform 2D and 3D game engine with a feature-rich editor
    Exec=${exeName} %f
    Terminal=false
    Categories=Development;IDE;
    StartupNotify=true
    StartupWMClass=Godot
    EOF

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/${exeName} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath libs}
  '';

  meta = {
    description = "Godot 4.8 development snapshot (official prebuilt Linux editor)";
    homepage = "https://godotengine.org";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = exeName;
  };
}
