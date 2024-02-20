{ buildPythonPackage
, fetchPypi
, tutor
}:

let
  pname = "tutor-license";
  version = "16.0.0";
in
buildPythonPackage {
  inherit pname version;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-Nfpr90yUMz6c6O3x+WLIjMOnnwpWnICXjj54FW0P/I4=";
  };

  doCheck = false;
  propagatedBuildInputs = [
    # Specify dependencies
    tutor
  ];
}
