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
  version = "15.3.3";

  disabled = isPyPy;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-xVQTVbLKKowVKtqjtInGBqJFXRd5V9QyTx98COEc0Ng=";
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