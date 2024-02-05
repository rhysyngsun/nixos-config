{ buildPythonPackage
, fetchPypi
, isPyPy
, appdirs
, click
, jinja2
, kubernetes
, mypy
, pycryptodome
, pyyaml
}:

buildPythonPackage rec {
  pname = "tutor";
  version = "17.0.1";

  disabled = isPyPy;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-UihFONeMwW9FxE6Oc0DJgsbMWuAue1L2B4LbG61sFgM=";
  };

  doCheck = false;
  propagatedBuildInputs = [
    # Specify dependencies
    appdirs
    click
    jinja2
    kubernetes
    mypy
    pycryptodome
    pyyaml
  ];
  checkPhase = "";
}
