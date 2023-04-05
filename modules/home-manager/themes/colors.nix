{ lib, ... }:
with lib;
{
  flavor = rec {
    name = "Mocha";
    lower = toLower name;
  };
  accent = rec {
    name = "Lavender";
    lower = toLower name;
  };
}
