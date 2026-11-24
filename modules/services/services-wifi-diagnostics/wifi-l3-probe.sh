# shellcheck shell=bash
# wifi-l3-probe - is the radio healthy while IP traffic is being discarded?
#
# Per round: signal, TX rate, gateway ARP state, ICMP to the gateway and to an
# off-net address, and the deltas for interface TX packets, TX drops and
# IcmpOutEchos. The diagnostic signature is ARP resolving and TX drops at zero
# with the pings still failing - that means the packets left this machine and
# the loss is upstream of it.

usage() {
  cat <<'USAGE'
usage: wifi-l3-probe <label> [--connect SSID] [--fallback SSID]
       wifi-l3-probe --check

  --connect SSID    activate SSID before probing (needs nmcli)
  --fallback SSID   return to SSID afterwards, only if --connect switched

env: IFACE=<name>  SAMPLES=<n>  GAP=<seconds>  OUTDIR=<dir>  EXT=<addr>
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
shift
CONNECT=""
FALLBACK=""
while [ $# -gt 0 ]; do
  case "$1" in
  --connect)
    CONNECT="${2:?--connect needs an SSID}"
    shift 2
    ;;
  --fallback)
    FALLBACK="${2:?--fallback needs an SSID}"
    shift 2
    ;;
  *) die "unknown option: $1" ;;
  esac
done

EXT="${EXT:-8.8.8.8}"
LOG="$(open_log l3probe "$LABEL")"
DAT="$(mktemp)"
trap 'rm -f "$DAT"' EXIT
exec > >(tee "$LOG") 2>&1

SWITCHED=0
if [ -n "$CONNECT" ]; then
  if ! have nmcli; then
    die "--connect needs nmcli; connect manually and omit the flag"
  fi
  if [ "$(ssid_now)" != "$CONNECT" ]; then
    printf 'connecting to %s...\n' "$CONNECT"
    if ! nmcli con up id "$CONNECT" >/dev/null 2>&1; then
      if ! nmcli dev wifi connect "$CONNECT" >/dev/null 2>&1; then
        die "could not activate '$CONNECT'"
      fi
    fi
    SWITCHED=1
    sleep 5
  fi
fi

require_connected
GW="$(gw_now)"

printf 'label=%s host=%s start=%s\n' "$LABEL" "$(hostname)" "$(date '+%F %T %Z')"
printf 'iface=%s ssid=%s bssid=%s ip=%s gw=%s mac=%s\n' \
  "$IF" "$(ssid_now)" "$(bssid_now)" "$(addr_now)" "$GW" "$(mac_now)"
printf 'probing %s for %s rounds, ~%ss apart\n\n' "$EXT" "$SAMPLES" "$((GAP + 1))"
printf '%6s %7s %9s %-12s %7s %9s %9s %9s %9s\n' \
  TIME SIGNAL TX-RATE GW-ARP PING-GW PING-EXT TXPKT-d TXDROP-d ICMPOUT-d

T0="$(date +%s)"
PP="$(num "$(txpkts)")"
PD="$(num "$(txdrop)")"
PI="$(num "$(icmpout)")"

for _ in $(seq 1 "$SAMPLES"); do
  sig="$(signal_now)"
  tx="$(txrate_now)"
  # Flushed each round so GW-ARP reports a fresh resolution, not a cached one.
  ip neigh flush dev "$IF" >/dev/null 2>&1 || true
  sleep 1

  if ping -n -c1 -W2 "$GW" >/dev/null 2>&1; then pg=ok; else pg=FAIL; fi
  nb="$(ip neigh show "$GW" dev "$IF" 2>/dev/null | awk '{print $NF; exit}')"
  if [ -z "$nb" ]; then nb="(none)"; fi
  if ping -n -c1 -W2 "$EXT" >/dev/null 2>&1; then pe=ok; else pe=FAIL; fi

  cp="$(num "$(txpkts)")"
  cd="$(num "$(txdrop)")"
  ci="$(num "$(icmpout)")"
  printf '%6s %7s %9s %-12s %7s %9s %9s %9s %9s\n' \
    "$(($(date +%s) - T0))s" "$sig" "$tx" "$nb" "$pg" "$pe" \
    "$((cp - PP))" "$((cd - PD))" "$((ci - PI))" | tee -a "$DAT"
  PP="$cp"
  PD="$cd"
  PI="$ci"
  sleep "$GAP"
done

echo
LOST="$(awk '$6=="FAIL"{n++} END{print n+0}' "$DAT")"
TOT="$(awk 'END{print NR+0}' "$DAT")"
PCT=0
if [ "$TOT" -gt 0 ]; then PCT="$((LOST * 100 / TOT))"; fi
printf '### SUMMARY %s: %s/%s samples lost (%s%%)\n' "$LABEL" "$LOST" "$TOT" "$PCT"

if [ "$LOST" -gt 0 ]; then
  echo '### during the lost samples'
  printf '    gateway ARP resolved : %s of %s\n' \
    "$(awk '$6=="FAIL" && $4!="(none)" && $4!="FAILED" && $4!="INCOMPLETE"{n++} END{print n+0}' "$DAT")" \
    "$LOST"
  printf '    TX drop deltas       : %s\n' \
    "$(awk '$6=="FAIL"{print $8}' "$DAT" | sort -un | paste -sd, -)"
  printf '    ICMP echoes built    : %s\n' \
    "$(awk '$6=="FAIL"{print $9}' "$DAT" | sort -un | paste -sd, -)"
  echo '### outage onsets - look for a repeating interval'
  awk '$6=="FAIL"{if(!p) printf "    onset %s\n", $1; p=1; next} {p=0}' "$DAT"
  echo
  echo '  ARP resolving, zero TX drops and echoes built, with pings still'
  echo '  failing, means this machine sent them and the loss is upstream.'
else
  echo '### no loss observed over this window'
fi

if [ "$SWITCHED" = "1" ] && [ -n "$FALLBACK" ]; then
  nmcli con up id "$FALLBACK" >/dev/null 2>&1 || true
fi
printf 'log: %s\n' "$LOG"
