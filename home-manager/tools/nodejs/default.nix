{ config, lib, pkgs, ... }:

let
  npmBin = ".npm-packages/bin";
  npmModules = ".npm-packages/lib/node_modules/";
  npmDirs = [
    npmBin
    npmModules
  ];
in
{
  home = {
    file = {
      ".npmrc".source = ./npmrc;
    } // lib.genAttrs
      (map (path: path + "/.keep") npmDirs)
      (_: { text = ""; });

    sessionPath = [
      "$HOME/${npmBin}"
    ];
    sessionVariables = {
      NODE_PATH = "$HOME/${npmModules}";
    };

    packages = with pkgs; [ nodejs ];
  };
}
