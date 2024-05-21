{ fetchFromGitHub }:
let
  src = (
    (fetchFromGitHub {
      owner = "catppuccin";
      repo = "palette";
      rev = "403e0effd3b1ba12e751e0d20e7704f1bc55e28e";
      hash = "sha256-uB+Diw0VpFToqvidx8yhOiNAdIkrbTuuyQwuReZFYjE=";
    })
    + "/palette-porcelain.json"
  );
in
builtins.fromJSON (builtins.readFile src)
