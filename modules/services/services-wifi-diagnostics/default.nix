{ ... }:
{
  flake.modules.nixos.services-wifi-diagnostics =
    { pkgs, ... }:
    let
      # Every script needs the same interface detection and metric helpers.
      # Concatenating beats sourcing: one copy, and shellcheck analyses the
      # whole program instead of emitting SC1091 for a path it cannot follow.
      mk =
        name:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = with pkgs; [
            iproute2 # ip, nstat
            iputils # ping, arping
            iw # signal, tx rate, SSID, BSSID
            # Not otherwise installed here, which is why the iwgetid/iwconfig
            # fallbacks in _common.sh had never executed. Naming it makes those
            # branches reachable rather than decorative.
            wirelesstools
            networkmanager # nmcli, for --connect and wifi-new-lease only
            gawk
            gnugrep
            coreutils
          ];
          text = builtins.readFile ./_common.sh + builtins.readFile (./. + "/${name}.sh");
        };

      commands = map mk [
        "wifi-l3-probe"
        "wifi-gw-watch"
        "wifi-new-lease"
        "wifi-dup-addr"
      ];
    in
    {
      environment.systemPackages = commands;
    };
}
