{ ... }:
{
  flake.modules.homeManager.programs-ai-pi-notify =
    { pkgs, lib, ... }:
    let
      # Same rationale as programs-ai-claude-notify: a settle fires after every
      # turn, so only turns longer than this are worth walking away from.
      stopThresholdSeconds = 60;

      # The notification logic - popup, replace-id, click-to-focus - is
      # agent-agnostic and already written. Rather than fork it, this builds a
      # second wrapper around the same source with the agent's name overridden.
      # A relative reference to a *file* under modules/ is safe: flake.nix:16
      # walks the tree for `.nix` only, so neither this .sh nor the .ts below is
      # mistaken for a flake-parts module.
      notify = pkgs.writeShellApplication {
        name = "pi-notify";
        runtimeInputs = with pkgs; [
          libnotify
          jq
          coreutils
          # setsid - the popup has to outlive the call, see claude-notify.sh.
          util-linux
          wezterm
          # KWin scripting; the only way to raise a window under Plasma Wayland.
          kdotool
        ];
        runtimeEnv = {
          CLAUDE_NOTIFY_STOP_THRESHOLD = toString stopThresholdSeconds;
          AGENT_NOTIFY_APP = "pi";
          AGENT_NOTIFY_NAME = "pi";
          # No pi mark ships anywhere and the repo does not carry one, so this
          # resolves by name out of the icon theme rather than by path. Swap in
          # a `"${./pi.svg}"` here if one ever lands.
          CLAUDE_NOTIFY_ICON = "dialog-information";
        };
        text = builtins.readFile ../programs-ai-claude-notify/claude-notify.sh;
      };
    in
    {
      # <agent-dir>/extensions/ is discovered automatically, so this needs no
      # `settings.extensions` entry. pi loads direct .ts files from there.
      home.file.".pi/agent/extensions/pi-notify.ts".source = ./notify.ts;

      # The extension resolves the binary from here rather than PATH, so it does
      # not matter what shell pi was launched from.
      home.sessionVariables.PI_NOTIFY_BIN = lib.getExe notify;

      # Exposed so the popups can be exercised by hand, e.g.
      #   echo '{"session_id":"x","cwd":"'"$PWD"'"}' | pi-notify attention
      home.packages = [ notify ];
    };
}
