{
  callPackage,
  sources,
  inputs,
}:
{
  cacert = callPackage ./cacert.nix { };
  agent-kit = callPackage ./agent-kit.nix { source = sources.odl-agent-kit; };
  witan = callPackage ./witan.nix {
    source = sources.odl-agent-kit;
    inherit inputs;
  };
}
