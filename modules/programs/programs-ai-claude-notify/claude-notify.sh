#!/usr/bin/env bash
# Desktop notifications for Claude Code, driven by its hook system.
#
# Claude Code has no notification setting of its own (checked against 2.1.223),
# so this is the only route to a Plasma popup. One subcommand per hook event;
# the hook's JSON payload arrives on stdin.
#
#   start      UserPromptSubmit - stamps the turn's start time
#   stop       Stop             - notifies only if the turn outran the threshold
#   attention  Notification     - notifies that Claude is waiting on input
#   __popup    internal         - the half that blocks waiting for a click
#
# Clicking a popup switches wezterm to the pane the session is running in and
# raises its window. See `send` and `popup` for why that needs two processes.
#
# Wrapped by writeShellApplication in ./default.nix, which supplies the shebang,
# `set -euo pipefail`, CLAUDE_NOTIFY_STOP_THRESHOLD, CLAUDE_NOTIFY_ICON, and a
# PATH carrying notify-send/jq/coreutils/wezterm/kdotool/setsid. The defaults
# below keep it runnable by hand too.

threshold="${CLAUDE_NOTIFY_STOP_THRESHOLD:-60}"
icon="${CLAUDE_NOTIFY_ICON:-dialog-information}"
state_dir="${XDG_RUNTIME_DIR:-/tmp}/claude-notify"

# The notifying agent's name. Everything else here is agent-agnostic, so a
# second agent reuses this script with nothing but these two overridden -
# see modules/programs/programs-ai-pi-notify. app is what Plasma groups and
# files notification settings under; name is what the popup titles read.
app="${AGENT_NOTIFY_APP:-Claude Code}"
name="${AGENT_NOTIFY_NAME:-Claude}"

# No session bus means no notification daemon to talk to - an ssh or
# systemd-launched session must not turn that into a failing hook.
[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] || exit 0

mkdir -p "$state_dir"

action="${1:-}"

# The blocking half, re-entered as a detached process by `send`. Plasma stacks
# notifications from the same app, so without a replace-id a busy day leaves a
# column of dead popups. Reusing one id per session also makes "finished"
# supersede "needs you" - and supersession closes the superseded popup, so its
# waiting notify-send exits without reporting a click. A stale focus cannot fire.
popup() {
  local urgency="$1" expire="$2" title="$3" body="$4" nid="$5" pane="$6"
  local -a extra=()
  if [ -s "$nid" ]; then
    extra+=(--replace-id="$(cat "$nid")")
  fi
  # No pane means nothing to focus - leave the popup inert rather than offering
  # a click that does nothing. `default` is the spec's "clicked the body"
  # action, which Plasma honours without drawing a button.
  if [ -n "$pane" ]; then
    extra+=(--action=default=Focus)
  fi

  # --action implies --wait, so stdout now carries the chosen action and the
  # notification id has to come out on its own fd.
  local chosen
  chosen="$(notify-send \
    --app-name="$app" \
    --urgency="$urgency" \
    --icon="$icon" \
    --expire-time="$expire" \
    --id-fd=3 \
    "${extra[@]}" \
    "$title" "$body" 3>"$nid" 2>/dev/null || true)"

  [ "$chosen" = default ] || return 0

  # activate-pane switches wezterm to the right tab; kdotool (KWin scripting)
  # is what actually brings the window forward under Plasma's Wayland session.
  wezterm cli activate-pane --pane-id "$pane" >/dev/null 2>&1 || true
  kdotool search --class org.wezfurlong.wezterm windowactivate >/dev/null 2>&1 || true
}

if [ "$action" = __popup ]; then
  shift
  popup "$@"
  exit 0
fi

payload="$(cat)"

field() { jq -r --arg k "$1" '.[$k] // ""' <<<"$payload" 2>/dev/null || true; }

session="$(field session_id)"
[ -n "$session" ] || session=unknown
# Slashes would escape the state dir, and a session id is the only field here
# that reaches a path.
session="${session//\//_}"

cwd="$(field cwd)"
project="$(basename "${cwd:-$PWD}")"

start_file="$state_dir/$session.start"
nid_file="$state_dir/$session.nid"

send() {
  # --action makes notify-send outlive the hook, so the popup has to be
  # detached. setsid puts it in its own session, out of reach of the kill that
  # follows the 5s hook timeout, and the /dev/null redirects matter just as
  # much: a child holding the hook's stdout pipe open makes Claude Code wait
  # for EOF - i.e. the full timeout - on every single turn.
  #
  # WEZTERM_PANE comes from the shell the session was launched in; hooks
  # inherit it. Absent (ssh, systemd) it is simply empty and the popup is inert.
  setsid --fork "${BASH_SOURCE[0]}" __popup \
    "$1" "$2" "$3" "$4" "$nid_file" "${WEZTERM_PANE:-}" \
    </dev/null >/dev/null 2>&1 || true
}

case "$action" in
start)
  date +%s >"$start_file"
  ;;

attention)
  message="$(field message)"
  [ -n "$message" ] || message="$app is waiting on you."
  # critical survives until dismissed under Plasma, which is the whole point: a
  # permission prompt that times out off-screen is worse than no notification.
  send critical 0 "$name needs you - $project" "$message"
  ;;

stop)
  # A Stop hook fires after *every* turn, including three-second ones, so the
  # UserPromptSubmit stamp is what makes this mean "the long thing finished".
  [ -s "$start_file" ] || exit 0
  started="$(cat "$start_file")"
  rm -f "$start_file"
  elapsed=$(($(date +%s) - started))
  [ "$elapsed" -ge "$threshold" ] || exit 0

  summary="$(field last_assistant_message | tr '\n' ' ')"
  summary="${summary:0:160}"
  [ -n "$summary" ] || summary="Turn finished."
  send normal 10000 \
    "$name finished - $project" \
    "$(printf '%s\n\n%ss' "$summary" "$elapsed")"
  ;;

*)
  printf 'claude-notify: unknown action %s\n' "${action:-<none>}" >&2
  ;;
esac

# A notification is never worth failing a turn over.
exit 0
