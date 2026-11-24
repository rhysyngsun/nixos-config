{ ... }:
{
  # The hook half of the `kubectl` rule in rules/k8s.md. The rule says what the
  # hazard is - the default context changes out from under you, so a command
  # written against one cluster runs against another - and this makes the
  # omission impossible rather than discouraged. Both halves are needed: a
  # denial with no rule behind it reads as a bug, and prose alone is a coin
  # flip at exactly the moment it matters.
  flake.modules.homeManager.programs-ai-k8s =
    { pkgs, ... }:
    let
      # Deny-only, like `searchGuard` in programs-ai-lean-ctx.nix and the force
      # push guard in programs-ai-claude-git.nix. A PreToolUse `allow` is a full
      # bypass of the permission system, so a script that can only emit `deny`
      # subtracts from what is permitted and never adds to it. Every gate in
      # programs-ai-claude.nix still applies on top.
      #
      # Fails open everywhere: bad payload, unparseable command line and
      # unknown tool all exit 0 silently, handing the call back to the normal
      # permission flow rather than blocking it.
      contextGuard =
        pkgs.writers.writePython3Bin "kubectl-context-guard"
          {
            flakeIgnore = [
              "E501" # the deny reason is a single long line
            ];
          }
          ''
            import json
            import os
            import re
            import shlex
            import sys

            BYPASS = "kubectl:bypass"

            # Subcommands that either manage the context itself or never reach a
            # cluster. `config` covers use-context, get-contexts and
            # current-context; requiring --context on those is circular.
            NO_CONTEXT_NEEDED = {
                "config",
                "completion",
                "options",
                "help",
                "__complete",
            }

            REASON = (
                "Blocked: this `kubectl` call names no context, so it runs against whatever "
                "`current-context` happens to be - which changes out from under you.\n\n"
                "Re-run it with the context spelled out:\n"
                "  kubectl --context <name> ...\n\n"
                "`kubectl config get-contexts` lists them, and needs no --context itself.\n\n"
                f"Genuinely need the default - a throwaway in a single-cluster kubeconfig? Append ' # {BYPASS}' "
                "to the shell command and it runs (still subject to the normal Bash permission rules)."
            )

            ENV_ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
            SPLIT_OPS = re.compile(r"\|\||&&|[|;&\n]")


            def silent():
                sys.exit(0)


            def deny():
                json.dump(
                    {
                        "hookSpecificOutput": {
                            "hookEventName": "PreToolUse",
                            "permissionDecision": "deny",
                            "permissionDecisionReason": REASON,
                        }
                    },
                    sys.stdout,
                )
                sys.exit(0)


            def segments(command):
                # Unlike the lean-ctx search guard, which deliberately looks at
                # the leading command only, every segment counts here. A second
                # kubectl in a `&&` chain reaches a cluster just as hard as the
                # first, and `… | kubectl apply -f -` puts the dangerous half on
                # the right of the pipe.
                #
                # A list rather than a generator, so the unbalanced-quote case
                # below really does reach the caller. Returning None from inside
                # a generator only stops iteration, which would have left the
                # caller's fail-open branch unreachable.
                out = []
                for part in SPLIT_OPS.split(command):
                    try:
                        toks = shlex.split(part)
                    except ValueError:
                        # Not a command line we understand. Fail open rather
                        # than guess at what it would have run.
                        return None
                    i = 0
                    while i < len(toks) and ENV_ASSIGN.match(toks[i]):
                        i += 1
                    if i >= len(toks):
                        continue
                    out.append((os.path.basename(toks[i]), toks[i + 1:]))
                return out


            def needs_context(args):
                for a in args:
                    if a == "--context" or a.startswith("--context="):
                        return False
                # The first non-flag token is the subcommand.
                #
                # Approximate, in the fail-open direction: a separated flag
                # value is indistinguishable from a subcommand here, so
                # `kubectl -n config get pods` - a namespace actually named
                # "config" - reads as the config subcommand and is allowed
                # through. The inverse never happens, and the common spellings
                # put the subcommand first, so this is not worth a table of
                # every value-taking global flag.
                for a in args:
                    if a.startswith("-"):
                        continue
                    return a not in NO_CONTEXT_NEEDED
                # A bare `kubectl` prints usage and contacts nothing.
                return False


            def main():
                if os.environ.get("KUBECTL_GUARD_OFF"):
                    silent()

                try:
                    payload = json.load(sys.stdin)
                except (ValueError, OSError):
                    silent()

                if not isinstance(payload, dict):
                    silent()
                if payload.get("tool_name") != "Bash":
                    silent()

                command = (payload.get("tool_input") or {}).get("command") or ""
                if BYPASS in command:
                    silent()

                found = segments(command)
                if found is None:
                    silent()
                for binname, args in found:
                    if binname == "kubectl" and needs_context(args):
                        deny()
                silent()


            main()
          '';
    in
    {
      # `settings.hooks` lists concatenate across home-manager modules, so this
      # sits alongside the lean-ctx and force-push entries rather than
      # replacing them.
      programs.claude-code.settings.hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${contextGuard}/bin/kubectl-context-guard";
              # Pure string parsing, no subprocess and no network, so this
              # bound never decides an outcome.
              timeout = 5;
            }
          ];
        }
      ];
    };
}
