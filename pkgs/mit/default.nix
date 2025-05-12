{ callPackage, sources }:
{
  cacert = callPackage ./cacert.nix { };
  agent-kit = callPackage ./agent-kit.nix { source = sources.odl-agent-kit; };
}
