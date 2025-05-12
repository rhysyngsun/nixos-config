{ pkgs, ... }:
let
  zoomHashes = {
    "6.3.11.7212" = "sha256-wSXb2v2qXoLXctmjOZpL0SiOP8+ySwpTDpJmPrfQQco=";
    "6.4.5.1259" = "sha256-oAsK92yTaLdi9YfIcMkTevrSsKr2nClcMjOBo5VYIEg=";
  };
in
{
  home.packages = [
    pkgs.discord
    pkgs.slack
    pkgs.element-desktop
    # pkgs.zoom-us
    (pkgs.zoom-us.overrideAttrs (
      _:
      let
        version = "6.4.5.1259";
      in
      {
        inherit version;
        src = pkgs.fetchurl {
          url = "https://zoom.us/client/${version}/zoom_x86_64.pkg.tar.xz";
          hash = zoomHashes.${version};
        };
      }
    ))
  ];
}
