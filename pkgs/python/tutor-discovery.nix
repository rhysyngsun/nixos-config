{ buildPythonPackage
, fetchPypi
, tutor }:

let
  pname = "tutor-discovery";
  version = "15.0.0";
in
buildPythonPackage {
  inherit pname version;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-OTl4C2oYquXf+pIYQl2L9uwXSQKMa3ceYZReIfKbHQM=";
  };

  doCheck = false;
  propagatedBuildInputs = [
    # Specify dependencies
    tutor
  ];
}