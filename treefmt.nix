{ pkgs, ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";
  # Enable the terraform formatter
  programs = {
    nixfmt-rfc-style.enable = true;
    shellcheck.enable = true;
    shfmt.enable = true;
  };
}
