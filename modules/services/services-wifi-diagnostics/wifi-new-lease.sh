# shellcheck shell=bash
# wifi-new-lease - obtain a different address on the same network.
#
# Sets a fresh ipv4.dhcp-client-id (DHCP option 61) on a NetworkManager
# connection and reconnects. If the server keys its binding on the client-id a
# new address follows; if it keys on the hardware address nothing changes and
# the setting is reverted. Distinguishes "this address is broken" from "this
# device or user is broken", and is a workaround in its own right.
#
# Changes only what this host asks for. No MAC change, no static address.

usage() {
  cat <<'USAGE'
usage: wifi-new-lease <nm-connection-name>
       wifi-new-lease --check

  Revert manually with:
    nmcli con modify '<name>' ipv4.dhcp-client-id ''

env: IFACE=<name>  OUTDIR=<dir>
USAGE
}

case "${1:-}" in
--check)
  show_check
  exit 0
  ;;
-h | --help)
  usage
  exit 0
  ;;
'')
  usage >&2
  exit 2
  ;;
esac

if ! have nmcli; then
  die "needs nmcli (NetworkManager)"
fi
CON="$1"
if ! nmcli -g connection.id con show "$CON" >/dev/null 2>&1; then
  die "no NetworkManager connection named '$CON'"
fi

LOG="$(open_log newlease "$(printf '%s' "$CON" | tr -c '[:alnum:]' '-')")"
exec > >(tee "$LOG") 2>&1

ORIG_ID="$(nmcli -g ipv4.dhcp-client-id con show "$CON" || true)"
printf 'connection=%s start=%s original-client-id=%s\n' \
  "$CON" "$(date '+%F %T %Z')" "'${ORIG_ID}'"

restore() {
  printf '\nrestoring client-id to %s\n' "'${ORIG_ID}'"
  nmcli con modify "$CON" ipv4.dhcp-client-id "$ORIG_ID" || true
}

echo '--- baseline'
if ! nmcli con up id "$CON" >/dev/null; then
  die "could not activate '$CON'"
fi
sleep 4
require_connected
BEFORE="$(addr_now)"
printf '    ssid=%s address=%s gw=%s\n' "$(ssid_now)" "$BEFORE" "$(gw_now)"

NEWID="$(hostname)-$(date +%s)"
printf '\n--- setting client-id=%s and reconnecting\n' "$NEWID"
nmcli con modify "$CON" ipv4.dhcp-client-id "$NEWID"
nmcli con down id "$CON" >/dev/null 2>&1 || true
sleep 2
if ! nmcli con up id "$CON" >/dev/null; then
  echo 'ACTIVATION FAILED with the new client-id - the server may be refusing it'
  restore
  exit 1
fi
sleep 4
AFTER="$(addr_now)"
printf '    ssid=%s address=%s gw=%s\n' "$(ssid_now)" "$AFTER" "$(gw_now)"

echo
echo '### RESULT'
if [ -n "$AFTER" ] && [ "$AFTER" != "$BEFORE" ]; then
  printf '  ADDRESS CHANGED: %s -> %s\n' "$BEFORE" "$AFTER"
  echo '  The binding is keyed on the DHCP client-id, not the hardware address.'
  echo '  Leaving the new client-id in place. Run wifi-l3-probe now to see'
  echo '  whether the fault follows the address or the device.'
  printf "  Revert with: nmcli con modify '%s' ipv4.dhcp-client-id '%s'\n" \
    "$CON" "$ORIG_ID"
else
  printf '  ADDRESS UNCHANGED: still %s\n' "$AFTER"
  echo '  The binding is keyed on the hardware address. Only a MAC change would'
  echo '  move it, which is a different conversation with whoever runs the net.'
  restore
fi
printf 'log: %s\n' "$LOG"
