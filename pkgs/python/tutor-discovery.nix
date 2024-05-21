{
  buildPythonPackage,
  fetchPypi,
  tutor,
}:

let
  pname = "tutor-discovery";
  version = "17.0.0";
in
buildPythonPackage {
  inherit pname version;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-Z7s3ScWr2O95PDgOo+j6zOPiPRe6ZDlkkufK5zfknew=";
  };

  doCheck = false;
  propagatedBuildInputs = [
    # Specify dependencies
    tutor
  ];
}
