{ lib, ... }:
with lib;
{
  networking.extraHosts = concatLines [
    (builtins.readFile ./hosts/open-learning.hosts)
    (builtins.readFile ./hosts/reddit.hosts)
  ];
}
