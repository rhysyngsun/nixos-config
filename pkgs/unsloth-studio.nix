{
  lib,
  appimageTools,
  cacert,
  source,
  ...
}:
let
  inherit (source) pname version src;

  contents = appimageTools.extract { inherit pname src version; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # buildFHSEnv appends this to the env's /etc/profile, and the generated `-init`
  # script is just `source /etc/profile` followed by `exec appimage-exec.sh`. So
  # everything exported here is inherited by the Tauri process, by the
  # install.sh it runs on first launch, and by the venv python that script
  # builds - which is the only place that needs it. Setting this on the desktop
  # entry instead would miss launches from a terminal.
  profile = ''
    # The bundled install.sh builds a venv on a uv-managed
    # python-build-standalone CPython, whose OpenSSL was configured with
    # cafile=/etc/ssl/cert.pem (absent on NixOS) and capath=/etc/ssl/certs
    # (present, but holding only *named* symlinks - capath mode needs hashed
    # `<hash>.0` links, which NixOS does not generate). So every
    # urllib.request.urlopen in the installer dies with
    # CERTIFICATE_VERIFY_FAILED. That is what killed the isolated-Node download,
    # and install_llama_prebuilt.py would have died next. install.sh sets no
    # cert variables of its own.
    #
    # Naming the bundle file is the entire fix, and only this one variable is
    # needed: curl, git, node/npm and uv all verify fine in here without it
    # (curl and git link the NixOS bundle, node ships its own roots, uv is
    # rustls). SSL_CERT_DIR is deliberately not set - neither candidate
    # directory has the hashed links capath mode wants, so it would be no better
    # than the broken default.
    #
    # Host bundle first, pinned cacert as fallback. On this host they are the
    # same store path (/etc/ssl/certs/ca-certificates.crt resolves straight into
    # pkgs.cacert), so this is not a purity trade-off - but only the host file
    # would grow if security.pki.certificateFiles is ever set, and the fallback
    # keeps the wrapper working where /etc/ssl is not NixOS-shaped. Note the MIT
    # CA is *not* in either bundle: open-learning installs it as a standalone
    # file at /etc/ssl/certs/mitca.crt. Nothing the installer fetches
    # (nodejs.org, pytorch.org, pypi.org, huggingface.co) needs it.
    if [ -z "''${SSL_CERT_FILE:-}" ]; then
      for _unsloth_ca in /etc/ssl/certs/ca-certificates.crt \
                         ${cacert}/etc/ssl/certs/ca-bundle.crt; do
        if [ -r "$_unsloth_ca" ]; then
          export SSL_CERT_FILE="$_unsloth_ca"
          break
        fi
      done
      unset _unsloth_ca
    fi

    # install.sh wants ~/.local/bin on the *next* shell's PATH, and appends an
    # export line to whichever rc file $SHELL names - here home-manager's
    # read-only ~/.zshrc store symlink. On 0.1.800 that failed with a raw
    # "Permission denied"; 0.1.903 wraps the append and degrades to a warning
    # ("Unsloth is installed and works; only the PATH line is missing"), so this
    # is no longer load-bearing. It is kept because putting the directory on
    # PATH satisfies the installer's own `_path_has_dir` guard, so it skips the
    # block entirely rather than warning - and because the `unsloth` CLI it
    # installs there is then actually reachable.
    #
    # Not UV_NO_MODIFY_PATH: that gates only the separate uv-bin-dir block,
    # which never runs once a uv is already on PATH. Not UNSLOTH_STUDIO_HOME
    # either - it does suppress the append by entering env-override mode, but it
    # moves DATA_DIR and the installer's bin dir with it.
    export PATH="$HOME/.local/bin:$PATH"
  '';

  extraPkgs =
    pkgs: with pkgs; [
      # Tauri's webview and HTTP stack. Neither is in appimageTools'
      # defaultFhsEnvArgs, and without them the AppImage cannot start at all.
      webkitgtk_4_1
      libsoup_3

      # The tray backend, dlopen'd by soname rather than linked - so it never
      # shows up in `ldd` on the bundled binary, only as the app's own "required
      # Linux libraries are missing" dialog at startup. The binary tries
      # libayatana-appindicator3.so.1 first and falls back to the deprecated
      # libappindicator3.so.1; this provides the former, so the fallback is
      # never needed.
      libayatana-appindicator

      # The AppImage bundles its own Ubuntu-built libsoup-3.0.so.0, which AppRun
      # puts ahead of ours on LD_LIBRARY_PATH, and that build links
      # libnghttp2.so.14 - a soname nothing in appimageTools' default FHS env
      # provides. The main binary fails to load outright without it:
      # "error while loading shared libraries: libnghttp2.so.14". nixpkgs'
      # nghttp2 ships exactly that soname.
      #
      # Not fixed by the libsoup_3 above: the bundled copy wins, so the env
      # needs the bundled copy's dependency, not ours.
      #
      # The one other unresolved soname in the bundle, libcurl-gnutls.so.4, is
      # deliberately left missing. It is wanted only by
      # usr/lib/gstreamer-1.0/libgstcurl.so, an optional plugin GStreamer skips
      # when it cannot load it, and the name is Debian's rename of libcurl -
      # nixpkgs builds libcurl.so.4, so satisfying it would mean faking a
      # soname for a plugin nothing here uses.
      nghttp2

      # Mandatory, not an optimisation. decide_node_source() in the backend's
      # studio/setup.sh returns "system" - skipping the nodejs.org tarball
      # download that previously failed - only for node `^20.19 || >=22.12 ||
      # >=23` *and* npm major >= 11; 24.21.0 with npm 11.19.0 clears both. Node
      # is needed even though the Tauri build ships its prebuilt frontend,
      # because setup.sh runs `npm install` in the backend's oxc-validator and
      # treats a non-zero exit as fatal. Pinned to the major rather than bare
      # `nodejs` so the version that gate was read against is stated here
      # instead of inherited from whatever the channel default becomes; they are
      # the same derivation today.
      nodejs_24

      # install.sh prefers a uv already on PATH over downloading astral's
      # installer, which also leaves the uv-bin-dir rc-writing block inert.
      uv

      # Fetches the git+https `triton_kernels` requirement; without it the
      # installer warns that the training speedup is skipped.
      git

      # Insurance only: every runtime dep arrives as a wheel, but a stray sdist
      # in a future dependency set would need a compiler. The FHS base carries
      # gcc.cc.lib, not gcc itself.
      gcc
    ];

  # Deliberately absent, each checked rather than assumed:
  #
  # - LD_LIBRARY_PATH for /run/opengl-driver/lib. container-init.cc already
  #   writes both opengl-driver lib dirs into the sandbox's /etc/ld.so.conf and
  #   runs ldconfig, so libcuda.so.1 resolves from the cache and torch reports
  #   the RTX 4070. Prepending it would only risk the driver's libGL/libEGL
  #   shadowing webkit's own resolution.
  # - cacert in extraPkgs. The bwrap launcher skips the FHS env's own /etc/ssl
  #   so it can bind the host's, so a cacert here would be unreachable from
  #   inside. It is referenced from `profile` instead, which both puts it in the
  #   closure and reaches it over the /nix bind mount.
  # - cmake / pkg-config / curl.dev. install.sh's own comment is explicit that
  #   these exist "solely for a llama.cpp source build the consumer path never
  #   does" - unslothai/llama.cpp publishes cpu/cuda12/cuda13/rocm/vulkan
  #   prebuilts, and the dependency check only picks a log message, never a code
  #   path. So they would buy nothing, and a source build without nvcc in here
  #   would be CPU-only anyway.
  # - curl, xdg-utils, zlib, openssl, stdenv.cc.cc.lib, libgomp. All already
  #   provided by appimageTools.defaultFhsEnvArgs or buildFHSEnv's base paths.

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
    platforms = [ "x86_64-linux" ];
  };
}
