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
        ];
        runtimeEnv.CLAUDE_NOTIFY_STOP_THRESHOLD = toString stopThresholdSeconds;
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
