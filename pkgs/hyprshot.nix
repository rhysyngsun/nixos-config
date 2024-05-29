{
  stdenv,
  lib,
  fetchFromGitHub,
  jq,
  grim,
  slurp,
  wl-clipboard,
  inotify-tools,
}:
stdenv.mkDerivation rec {

  pname = "hyprshot";
  version = "1.2.4-dev";

  src = fetchFromGitHub {
    owner = "Gustash";
    repo = "Hyprshot";
    rev = "36dbe2e6e97fb96bf524193bf91f3d172e9011a5";
    hash = "sha256-n1hDJ4Bi0zBI/Gp8iP9w9rt1nbGSayZ4V75CxOzSfFg=";
  };

  buildInputs = [
    jq
    grim
    slurp
    wl-clipboard
    inotify-tools
  ];

  dontUnpack = true;
  installPhase = ''
    install -D $src/hyprshot $out/bin/hyprshot
    chmod +x $out/bin/hyprshot
  '';
}
