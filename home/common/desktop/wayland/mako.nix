{ pkgs, ... }:

{
  home.packages = with pkgs; [libnotify];
  services.mako = {
    enable = true;
    defaultTimeout = 5000;

    extraConfig = ''
      # Colors

      background-color=#1e1e2e
      text-color=#cdd6f4
      border-color=#89b4fa
      progress-color=over #313244
      border-radius=5

      [urgency=high]
      border-color=#fab387
    '';
  };
}