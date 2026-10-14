{ ... }:
{
  flake.modules.homeManager.programs-ai-claude-notify =
    { pkgs, lib, ... }:
    let
      # A Stop hook fires after *every* turn, including three-second ones, so
      # notifying unconditionally is pure noise. A UserPromptSubmit stamp lets
      # the Stop hook ask "was this actually worth walking away from?" - only
      # turns longer than this notify. Single knob; retune here.
      stopThresholdSeconds = 60;

      notify = pkgs.writeShellApplication {
        name = "claude-notify";
        runtimeInputs = with pkgs; [
          libnotify
          jq
          coreutils
          # setsid - the popup has to outlive the hook, see claude-notify.sh.
          util-linux
          # Already in this user's closure via programs-wezterm, so naming it
          # here costs nothing and pins the focus call to a real path.
          wezterm
          # KWin scripting is the only way to raise a window under Plasma's
          # Wayland session; kdotool is a thin wrapper around it.
          kdotool
        ];
        runtimeEnv = {
          CLAUDE_NOTIFY_STOP_THRESHOLD = toString stopThresholdSeconds;
          # notify-send takes an absolute path here. Nothing ships a Claude
          # mark - not the claude-code npm package, not Breeze - so the repo
          # carries one. No hicolor wrapper derivation: that would only matter
          # if the icon were resolved by *name*, which then drags in
          # XDG_DATA_DIRS and the icon cache.
          CLAUDE_NOTIFY_ICON = "${./claude.svg}";
        };
        text = builtins.readFile ./claude-notify.sh;
      };

      mkHook = arg: {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "${lib.getExe notify} ${arg}";
            timeout = 5;
          }
        ];
      };
    in
    {
      # These concatenate with the witan hooks in programs-ai-claude-mit.nix
      # rather than colliding with them: `settings` is a freeform JSON type, so
      # same-path list definitions from two modules merge by concatenation.
      programs.claude-code.settings.hooks = {
        Notification = [ (mkHook "attention") ];
        UserPromptSubmit = [ (mkHook "start") ];
        Stop = [ (mkHook "stop") ];
      };

      # Exposed so the hook can be exercised by hand without starting a session.
      home.packages = [ notify ];
    };
}
