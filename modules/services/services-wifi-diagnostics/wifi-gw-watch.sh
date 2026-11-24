# shellcheck shell=bash
# wifi-gw-watch - is the default gateway one device, or several?
#
# Polls the gateway's resolved MAC against reachability at 2s resolution.
# Two devices alternately answering as one gateway address - a mismatched
# VRRP/HSRP pair, a flapping controller - looks like a perfectly healthy
# neighbour entry to anything that records only the ARP *state*.
#
# Needs no privileges: it pings and reads this host's own neighbour cache.

usage() {
  cat <<'USAGE'
usage: wifi-gw-watch <label>
       wifi-gw-watch --check

env: IFACE=<name>  SAMPLES=<n>  GAP=<seconds>  OUTDIR=<dir>  EXT=<addr>
     defaults here are SAMPLES=180 GAP=2, about six minutes
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

LABEL="$1"
# Fine resolution is the point of this one: a 90s period is invisible at 6s.
SAMPLES="${SAMPLES:-180}"
GAP="${GAP:-2}"
EXT="${EXT:-8.8.8.8}"

require_connected
GW="$(gw_now)"

LOG="$(open_log gwwatch "$LABEL")"
DAT="$(mktemp)"
trap 'rm -f "$DAT"' EXIT
exec > >(tee "$LOG") 2>&1

printf 'label=%s host=%s start=%s\n' "$LABEL" "$(hostname)" "$(date '+%F %T %Z')"
printf 'iface=%s ssid=%s bssid=%s ip=%s gw=%s\n' \
  "$IF" "$(ssid_now)" "$(bssid_now)" "$(addr_now)" "$GW"
printf 'sampling every %ss x %s (~%s min)\n\n' \
  "$GAP" "$SAMPLES" "$((SAMPLES * GAP / 60))"
printf '%6s %-19s %-12s %7s\n' TIME GW-MAC GW-STATE PING

T0="$(date +%s)"
for _ in $(seq 1 "$SAMPLES"); do
  if ping -n -c1 -W1 "$EXT" >/dev/null 2>&1; then p=ok; else p=FAIL; fi
  line="$(ip neigh show "$GW" dev "$IF" 2>/dev/null || true)"
  mac="$(printf '%s' "$line" | sed -n 's/.*lladdr \([0-9a-f:]\{17\}\).*/\1/p')"
  state="$(printf '%s' "$line" | awk '{print $NF}')"
  if [ -z "$mac" ]; then mac="(none)"; fi
  if [ -z "$state" ]; then state="(none)"; fi
  printf '%6s %-19s %-12s %7s\n' \
    "$(($(date +%s) - T0))s" "$mac" "$state" "$p" | tee -a "$DAT"
  sleep "$GAP"
done

echo
echo '### distinct gateway MACs, all samples'
awk '$2 ~ /:/ {print $2}' "$DAT" | sort | uniq -c
echo '### distinct gateway MACs during FAIL samples'
awk '$4=="FAIL" && $2 ~ /:/ {print $2}' "$DAT" | sort | uniq -c
LOST="$(awk '$4=="FAIL"{n++} END{print n+0}' "$DAT")"
TOT="$(awk 'END{print NR+0}' "$DAT")"
PCT=0
if [ "$TOT" -gt 0 ]; then PCT="$((LOST * 100 / TOT))"; fi
printf '### SUMMARY %s: %s/%s samples lost (%s%%)\n' "$LABEL" "$LOST" "$TOT" "$PCT"
printf 'log: %s\n' "$LOG"
