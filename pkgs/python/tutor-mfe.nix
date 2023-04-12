{ buildPythonPackage
, fetchPypi
, tutor }:

let
  pname = "tutor-mfe";
  version = "15.0.5";
in
buildPythonPackage {
  inherit pname version;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-vq3VlTgbavhLJJY3GSLCMFYrbM9RW2c48UopTeiuLAA=";
  };

  doCheck = false;
  propagatedBuildInputs = [
    # Specify dependencies
    tutor
  ];
}
