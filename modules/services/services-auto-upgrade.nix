{ ... }:
let
  # The flake is a user checkout, not /etc/nixos, so the unattended rebuild has
  # to reach into nathan's home. Spelled out absolutely for the same reason
  # `sops.age.keyFile` is in the home roll-ups: there is no config to derive it
  # from at the point it is needed.
  repo = "/home/nathan/nixos";
  owner = "nathan";
in
{
  flake.modules.nixos.services-auto-upgrade =
    { config, pkgs, ... }:
    let
      preUpgrade = pkgs.writeShellApplication {
        name = "nixos-upgrade-pre";
        runtimeInputs = [
          pkgs.gitMinimal
          pkgs.util-linux
          config.nix.package
        ];
        text = ''
          cd ${repo}

          # Nix applies git-tree semantics to a bare path, so untracked files do
          # not exist to the build. This is `just git-stage`.
          runuser -u ${owner} -- env HOME=/home/${owner} git add -A

          # system.autoUpgrade honours whatever lock it is handed, so without
          # this the weekly rebuild would reproduce the identical closure
          # forever. Run as ${owner} so the commit carries their git identity
          # and the working tree is not left owned by root.
          runuser -u ${owner} -- env HOME=/home/${owner} \
            nix flake update --commit-lock-file
        '';
      };

      notifyFailure = pkgs.writeShellApplication {
        name = "nixos-upgrade-notify-failure";
        runtimeInputs = [
          pkgs.libnotify
          pkgs.util-linux
        ];
        text = ''
          uid="$(id -u ${owner})"
          bus="/run/user/$uid/bus"

          echo "nixos-upgrade failed; journalctl -u nixos-upgrade -e" >&2

          # Nobody logged in: the journal line above is the whole report.
          [ -S "$bus" ] || exit 0

          runuser -u ${owner} -- env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
            notify-send -u critical \
              "NixOS auto-upgrade failed" \
              "journalctl -u nixos-upgrade -e"
        '';
      };
    in
    {
      system.autoUpgrade = {
        enable = true;
        flake = "${repo}#lilith";

        # nvidia-prime under a live SDDM/plasma/niri session. A switch across a
        # nixpkgs bump restarts the session's services and leaves the loaded
        # kernel module mismatched against the new userspace GL, so stage the
        # generation and let a reboot apply it.
        operation = "boot";

        # --upgrade is channel-era. The input bump is ExecStartPre's job.
        upgrade = false;

        dates = "Sun 04:00";
        randomizedDelaySec = "45min";
        persistent = true;
      };

      # Additions to the unit from nixos/modules/tasks/auto-upgrade.nix, which
      # owns Type, script, path, startAt and the network-online ordering.
      # ExecStartPre failing aborts ExecStart, which is what we want: a failed
      # input bump should not be followed by a rebuild of the unchanged lock.
      systemd.services.nixos-upgrade = {
        serviceConfig.ExecStartPre = "${preUpgrade}/bin/nixos-upgrade-pre";
        onFailure = [ "nixos-upgrade-failed.service" ];
      };

      # nixos-rebuild runs as root against a checkout owned by nathan, and
      # Nix's git fetcher is libgit2, whose validate_ownership() rejects that
      # outright (GIT_EOWNER, "not owned by current user"). It consults
      # safe.directory via load_global_config, which includes the system
      # config, so /etc/gitconfig is where root can be told to trust the path.
      # No trailing slash - libgit2 skips any value that ends in one.
      programs.git = {
        enable = true;
        config.safe.directory = [ repo ];
      };

      systemd.services.nixos-upgrade-failed = {
        description = "Report a failed NixOS auto-upgrade";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${notifyFailure}/bin/nixos-upgrade-notify-failure";
        };
      };
    };
}
