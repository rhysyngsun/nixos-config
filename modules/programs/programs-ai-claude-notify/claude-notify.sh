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
#
# Wrapped by writeShellApplication in ./default.nix, which supplies the shebang,
# `set -euo pipefail`, CLAUDE_NOTIFY_STOP_THRESHOLD, and a PATH carrying
# notify-send/jq/coreutils. The defaults below keep it runnable by hand too.

threshold="${CLAUDE_NOTIFY_STOP_THRESHOLD:-60}"
state_dir="${XDG_RUNTIME_DIR:-/tmp}/claude-notify"

# No session bus means no notification daemon to talk to - an ssh or
# systemd-launched session must not turn that into a failing hook.
[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] || exit 0

mkdir -p "$state_dir"

action="${1:-}"
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

# Plasma stacks notifications from the same app, so without a replace-id a busy
# day leaves a column of dead popups. Reusing one id per session also makes
# "finished" supersede "needs you".
send() {
  local urgency="$1" icon="$2" expire="$3" title="$4" body="$5"
  local -a replace=()
  if [ -s "$nid_file" ]; then
    replace=(--replace-id="$(cat "$nid_file")")
  fi
  notify-send \
    --app-name="Claude Code" \
    --urgency="$urgency" \
    --icon="$icon" \
    --expire-time="$expire" \
    --print-id \
    "${replace[@]}" \
    "$title" "$body" >"$nid_file" 2>/dev/null || true
}

case "$action" in
start)
  date +%s >"$start_file"
  ;;

attention)
  message="$(field message)"
  [ -n "$message" ] || message="Claude Code is waiting on you."
  # critical survives until dismissed under Plasma, which is the whole point: a
  # permission prompt that times out off-screen is worse than no notification.
  send critical dialog-question 0 "Claude needs you - $project" "$message"
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
  send normal dialog-information 10000 \
    "Claude finished - $project" \
    "$(printf '%s\n\n%ss' "$summary" "$elapsed")"
  ;;

*)
  printf 'claude-notify: unknown action %s\n' "${action:-<none>}" >&2
  ;;
esac

# A notification is never worth failing a turn over.
exit 0
