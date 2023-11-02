{ pkgs, lib, fetchurl }:
pkgs.mkDerivation {

  pname = "pants";
  version = "0.10.4";

  src = fetchurl {
    url = "https://github.com/pantsbuild/scie-pants/releases/download/v${version}/scie-pants-linux-${pkgs.system}";
    repo = "scie-pants";
    rev = "v${version}";
    hash = "";
  };


  meta = with lib; {
    description = "A a fast, scalable, user-friendly build system for codebases of all sizes";
    homepage = "https://github.com/pantsbuild/scie-pants";
    license = licenses.asl20;
    maintainers = [];
  };
}