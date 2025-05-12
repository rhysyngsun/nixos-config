{
  appimageTools,
  source,
  ...
}: let
  inherit (source) pname version src;
in
  appimageTools.wrapType2 {
    inherit version pname src;

    extraInstallCommands = let
      contents = appimageTools.extractType1 {inherit pname src version;};
    in ''
      mkdir -p "$out/share/applications"
      mkdir -p "$out/share/lib/headlamp"
      cp -r ${contents}/* "$out/share/lib/headlamp"
      cp "${contents}/${pname}.desktop" "$out/share/applications/"
      substituteInPlace $out/share/applications/${pname}.desktop --replace 'Exec=AppRun' 'Exec=${pname}'
    '';
  }
