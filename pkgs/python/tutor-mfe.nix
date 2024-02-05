{ buildPythonPackage
, fetchPypi
, tutor }:

let
  pname = "tutor-mfe";
  version = "17.0.0";
in
buildPythonPackage {
  inherit pname version;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-DV3x5w0SN8tH71X4Rm/4KueItLUavQyS9LU3vXnl7FM=";
  };

  doCheck = false;
  propagatedBuildInputs = [
    # Specify dependencies
    tutor
  ];
}
