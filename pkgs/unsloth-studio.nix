{
  lib,
  appimageTools,
  source,
  ...
}:
let
  inherit (source) pname src;

  # nvfetcher tracks a composite "version" so that one `$ver` can spell both
  # halves of the download URL (`v0.1.800-beta/...-0_1_800_beta-...`) - see the
  # comment on [unsloth] in nvfetcher.toml. Everything from the first `/` on is
  # filename scaffolding, not part of the version.
  version = lib.head (lib.splitString "/" source.version);

  contents = appimageTools.extract { inherit pname src version; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # A Tauri app: webkitgtk and libsoup are not part of appimageTools' default
  # FHS env, and without them the AppImage cannot even start.
  #
  # libayatana-appindicator is the tray backend, and it is *dlopen'd by soname*
  # rather than linked, so it does not show up in `ldd` on the bundled binary -
  # it only surfaces as the app's own "required Linux libraries are missing"
  # dialog at startup. The binary tries libayatana-appindicator3.so.1 first and
  # falls back to the deprecated libappindicator3.so.1; this package provides
  # the former, so the fallback is not needed.
  #
  # The rest are for Unsloth Studio, the Python backend the app installs
  # imperatively into ~/.unsloth/studio on first launch - it prefers `uv`, falls
  # back to git/curl/a compiler, and opens the web UI through xdg-open.
  extraPkgs =
    pkgs: with pkgs; [
      webkitgtk_4_1
      libsoup_3
      libayatana-appindicator
      uv
      git
      curl
      gcc
      xdg-utils
    ];

  # The bundled entry's `Exec=unsloth-studio` names the binary inside the image,
  # which is also what wrapType2 calls the wrapper it puts on PATH - so the
  # entry can be installed as-is. Keeping `pname` equal to that name is what
  # makes that true; renaming the package means patching Exec again.
  extraInstallCommands = ''
    install -Dm444 ${contents}/Unsloth.desktop -t $out/share/applications
    cp -r ${contents}/usr/share/icons $out/share/
  '';

  meta = {
    description = "Unsloth Desktop - local LLM fine-tuning and training UI";
    homepage = "https://github.com/unslothai/unsloth";
    license = lib.licenses.agpl3Only;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
