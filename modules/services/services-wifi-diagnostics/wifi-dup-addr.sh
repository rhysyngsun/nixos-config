# shellcheck shell=bash
# wifi-dup-addr - is another host holding this address?
#
# Probes across a full outage cycle rather than in one burst, so a responder
# that only answers while traffic is being discarded is not missed, and
# interleaves reachability so a hit can be correlated with the outage windows.
#
# Sends ARP probes and needs root, so clear it with whoever runs the network
# first. A negative result does NOT refute a duplicate: proxy ARP, client
# isolation, or a stale binding in the DHCP or controller database would each
# produce exactly this output with nothing to answer.

usage() {
  cat <<'USAGE'
usage: wifi-dup-addr <label>        (run under sudo, or it will ask)
       wifi-dup-addr --check

env: IFACE=<name>  SAMPLES=<n>  GAP=<seconds>  OUTDIR=<dir>  EXT=<addr>
     ARP_EVERY=<n>  probe on every nth sample, default 3
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

if ! have arping; then
  die "needs arping (iputils)"
fi
LABEL="$1"
SAMPLES="${SAMPLES:-150}"
GAP="${GAP:-2}"
EXT="${EXT:-8.8.8.8}"
ARP_EVERY="${ARP_EVERY:-3}"

# Cache credentials before output is redirected, so the prompt is visible.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if ! have sudo; then
    die "not root and no sudo available; re-run as root"
  fi
  SUDO="sudo"
  echo 'caching sudo credentials so the sampling loop does not prompt...'
  sudo -v
fi

require_connected
IP4="$(addr_now | cut -d/ -f1)"
GW="$(gw_now)"
MY="$(mac_now)"

LOG="$(open_log dupaddr "$LABEL")"
DAT="$(mktemp)"
trap 'rm -f "$DAT"' EXIT
exec > >(tee "$LOG") 2>&1

printf 'label=%s host=%s start=%s\n' "$LABEL" "$(hostname)" "$(date '+%F %T %Z')"
printf 'iface=%s ssid=%s ip=%s gw=%s mac=%s\n' \
  "$IF" "$(ssid_now)" "$IP4" "$GW" "$MY"

echo
printf '### strict duplicate-address detection for %s (sender 0.0.0.0)\n' "$IP4"
$SUDO arping -D -I "$IF" -c 4 "$IP4" 2>&1 | tail -3 || true

echo
printf '### probing across the cycle: who answers for %s, and when\n' "$IP4"
printf '%6s %-19s %7s %-26s\n' TIME GW-MAC PING ARP-REPLY

T0="$(date +%s)"
i=0
for _ in $(seq 1 "$SAMPLES"); do
  i="$((i + 1))"
  if ping -n -c1 -W1 "$EXT" >/dev/null 2>&1; then p=ok; else p=FAIL; fi
  line="$(ip neigh show "$GW" dev "$IF" 2>/dev/null || true)"
  mac="$(printf '%s' "$line" | sed -n 's/.*lladdr \([0-9a-f:]\{17\}\).*/\1/p')"
  if [ -z "$mac" ]; then mac="(none)"; fi

  r="-"
  if [ "$((i % ARP_EVERY))" -eq 0 ]; then
    out="$($SUDO arping -I "$IF" -c 1 -w 1 "$IP4" 2>&1 || true)"
    r="$(printf '%s' "$out" |
      sed -n 's/.*reply from [0-9.]* \[\([0-9a-fA-F:]*\)\].*/\1/p' | head -1)"
    if [ -z "$r" ]; then
      r="none"
    elif [ "${r,,}" = "${MY,,}" ]; then
      r="self"
    else
      r="FOREIGN:$r"
    fi
  fi
  printf '%6s %-19s %7s %-26s\n' \
    "$(($(date +%s) - T0))s" "$mac" "$p" "$r" | tee -a "$DAT"
  sleep "$GAP"
done

echo
echo '### VERDICT'
if awk '$4 ~ /^FOREIGN:/{found=1} END{exit !found}' "$DAT"; then
  printf '  DUPLICATE FOUND - another host answers for %s\n' "$IP4"
  awk '$4 ~ /^FOREIGN:/{print "   ", $4}' "$DAT" | sort | uniq -c
  echo '  during FAIL samples specifically:'
  awk '$3=="FAIL" && $4 ~ /^FOREIGN:/{print "   ", $4}' "$DAT" | sort | uniq -c
else
  echo '  no foreign responder seen. NOT conclusive: proxy ARP, client'
  echo '  isolation, or a stale controller binding would all look like this.'
fi
echo '### distinct gateway MACs'
awk '$2 ~ /:/ {print $2}' "$DAT" | sort | uniq -c
LOST="$(awk '$3=="FAIL"{n++} END{print n+0}' "$DAT")"
TOT="$(awk 'END{print NR+0}' "$DAT")"
PCT=0
if [ "$TOT" -gt 0 ]; then PCT="$((LOST * 100 / TOT))"; fi
printf '### SUMMARY %s: %s/%s samples lost (%s%%)\n' "$LABEL" "$LOST" "$TOT" "$PCT"
printf 'log: %s\n' "$LOG"
