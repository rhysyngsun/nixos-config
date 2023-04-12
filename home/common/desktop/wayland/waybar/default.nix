args@{ pkgs, lib, ... }:
{
  programs.waybar = {
    enable = true;

    # need to reassign this because we've overlayed it for hyprland
    package = pkgs.waybar.overrideAttrs (_oa: {
      src = pkgs.fetchFromGitHub {
        owner = "Alexays";
        repo = "Waybar";
        rev = "bd908f6d9750209baffe1ce9d43006130a26c4ed";
        hash = "sha256-BdJcpvxIv8MS4iWB/qAGwx5/7+3wob5JNQZ3Zk86c1U=";
      };
    });

    style = import ./style.nix args;
    settings = import ./settings.nix args;

    # systemd = {
    #   enable = true;
    #   target = "hyprland-session.target";
    # };
  };

  # systemd.user.services.waybar = {
  #   Unit = {
  #     After = [ "hyprland-session.target" ];
  #   };

  #   Service = {
  #     ExecStart = lib.mkForce ''
  #       ${lib.getExe pkgs.bash} ${./scripts/launch_waybar.sh}
  #     '';
  #   };
  # };
}
