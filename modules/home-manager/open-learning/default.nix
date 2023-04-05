{ pkgs, ... }:
let
  tutor =
    let
      pname = "tutor";
      version = "15.3.3";
    in
    with pkgs.python3Packages; buildPythonPackage {
      inherit pname version;

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
    };

  tutor-mfe =
    let
      pname = "tutor-mfe";
      version = "15.0.5";
    in
    with pkgs.python3Packages; buildPythonPackage {
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
    };

  tutor-discovery =
    let
      pname = "tutor-discovery";
      version = "15.0.0";
    in
    with pkgs.python3Packages; buildPythonPackage {
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
    };

  tutor-license =
    let
      pname = "tutor-license";
      version = "15.0.0";
    in
    with pkgs.python3Packages; buildPythonPackage {
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
    };

  python-packages = ps: [
    tutor
    tutor-discovery
    tutor-license
    tutor-mfe
  ];
in
{

  # networking.extraHosts = concatLines [
  #   builtins.readFile ./hosts/open-learning.hosts
  #   builtins.readFile ./hosts/reddit.hosts
  # ];

  home = {
    packages = with pkgs; [
      (python3.withPackages python-packages)
    ];

    sessionVariables = {
      # tutor should use `docker compose` instead of deprecated `docker-compose`
      TUTOR_USE_COMPOSE_SUBCOMMAND = "1";
    };
  };
}
