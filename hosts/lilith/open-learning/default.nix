{ lib, pkgs, ... }:
with lib;
{
  networking.extraHosts = concatLines [
    (builtins.readFile ./hosts/open-learning.hosts)
    (builtins.readFile ./hosts/reddit.hosts)
  ];

  environment.etc."ssl/certs/mitca.crt".source = "${pkgs.mit.cacert}/etc/ssl/certs/mitca.crt";
}
