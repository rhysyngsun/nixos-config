{ buildPythonPackage
, fetchPypi
, tutor }:

let
  pname = "tutor-license";
  version = "15.0.0";
in
buildPythonPackage {
  inherit pname version;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-i4pI46GKqQ8XK2XZPnW5f69JAnvSXD1ml0jk0plGH/o=";
  };

  doCheck = false;
  propagatedBuildInputs = [
    # Specify dependencies
    tutor
  ];
}