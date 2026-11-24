# shellcheck shell=bash
# Shared helpers for the wifi-* diagnostics. Concatenated ahead of each script
# by default.nix, so there is no `source` to resolve and shellcheck sees the
# whole program.
#
# writeShellApplication supplies `set -o errexit -o nounset -o pipefail`, so
# every command whose failure is expected is written as an `if` or guarded
# explicitly. Do not add bare `[ t ] && action` statements: under errexit a
# false test ends the script.

SAMPLES="${SAMPLES:-40}"
GAP="${GAP:-5}"
OUTDIR="${OUTDIR:-.}"

die() {
  printf '%s\n' "$*" >&2
  exit 1
}
have() { command -v "$1" >/dev/null 2>&1; }

# --- interface -------------------------------------------------------------

# A wireless interface is the one exposing a phy80211 link; fall back to
# whatever owns the default route so this still works on wired links.
detect_iface() {
  local i
  for i in /sys/class/net/*; do
    if [ -e "$i/phy80211" ]; then
      basename "$i"
      return 0
    fi
  done
  ip route 2>/dev/null |
    awk '/^default/{for(j=1;j<=NF;j++) if($j=="dev"){print $(j+1); exit}}'
}

IF="${IFACE:-$(detect_iface)}"
if [ -z "$IF" ]; then
  die "no network interface found; set IFACE=<name> and retry"
fi
if [ ! -e "/sys/class/net/$IF" ]; then
  die "interface '$IF' does not exist"
fi

# --- link metrics, each degrading to '?' rather than failing ---------------

ssid_now() {
  if have iw; then
    iw dev "$IF" link 2>/dev/null | sed -n 's/^[[:space:]]*SSID: //p'
  elif have iwgetid; then
    iwgetid -r "$IF" 2>/dev/null || true
  elif have iwconfig; then
    iwconfig "$IF" 2>/dev/null | sed -n 's/.*ESSID:"\([^"]*\)".*/\1/p'
  fi
}

signal_now() {
  local v=""
  if have iw; then
    v=$(iw dev "$IF" station dump 2>/dev/null | awk '/signal:/{print $2; exit}')
    if [ -z "$v" ]; then
      v=$(iw dev "$IF" link 2>/dev/null | awk '/signal:/{print $2; exit}')
    fi
  fi
  # /proc/net/wireless reports level as dBm+256 on many drivers.
  if [ -z "$v" ] && [ -r /proc/net/wireless ]; then
    v=$(awk -v i="$IF:" '$1==i{gsub(/\./,"",$4); print ($4>0 ? $4-256 : $4); exit}' \
      /proc/net/wireless)
  fi
  printf '%s' "${v:-?}"
}

txrate_now() {
  local v=""
  if have iw; then
    v=$(iw dev "$IF" link 2>/dev/null | awk '/tx bitrate/{print $3; exit}')
  fi
  if [ -z "$v" ] && have iwconfig; then
    v=$(iwconfig "$IF" 2>/dev/null | sed -n 's/.*Bit Rate[=:]\([0-9.]*\).*/\1/p')
  fi
  printf '%s' "${v:-?}"
}

bssid_now() {
  local v=""
  if have iw; then
    v=$(iw dev "$IF" link 2>/dev/null | awk '/Connected to/{print $3; exit}')
  fi
  printf '%s' "${v:-?}"
}

# --- addressing ------------------------------------------------------------

addr_now() { ip -4 -o addr show "$IF" 2>/dev/null | awk '{print $4; exit}'; }
gw_now() { ip -4 route 2>/dev/null | awk '/^default/{print $3; exit}'; }
mac_now() { cat "/sys/class/net/$IF/address" 2>/dev/null || printf '?'; }

# --- counters --------------------------------------------------------------
# `ip -s link` prints "RX: ..." then a data row, then "TX: ..." then its row,
# where the TX fields are bytes packets errors dropped.

txpkts() { ip -s link show "$IF" 2>/dev/null | awk '/TX:/{getline; print $2; exit}'; }
txdrop() { ip -s link show "$IF" 2>/dev/null | awk '/TX:/{getline; print $4; exit}'; }

icmpout() {
  local v=""
  if have nstat; then
    v=$(nstat -az 2>/dev/null | awk '/IcmpOutEchos/{print $2; exit}')
  fi
  if [ -z "$v" ] && [ -r /proc/net/snmp ]; then
    v=$(awk '/^Icmp:/{
          if (h) { for (j=1;j<=NF;j++) if (hdr[j]=="OutEchos") { print $j; exit } }
          else   { for (j=1;j<=NF;j++) hdr[j]=$j; h=1 }
        }' /proc/net/snmp)
  fi
  printf '%s' "${v:-0}"
}

# Counter deltas are subtracted, so a '?' would abort the arithmetic.
num() {
  case "${1:-}" in
  '' | *[!0-9]*) printf '0' ;;
  *) printf '%s' "$1" ;;
  esac
}

# --- shared plumbing -------------------------------------------------------

require_connected() {
  if [ -z "$(addr_now)" ]; then
    die "no IPv4 address on $IF - not connected?"
  fi
  if [ -z "$(gw_now)" ]; then
    die "no default gateway on $IF - not connected?"
  fi
}

# Logs land in the working directory so the caller controls where evidence goes.
open_log() {
  local name="$1" label="$2"
  mkdir -p "$OUTDIR"
  printf '%s/%s-%s-%s.log' "$OUTDIR" "$name" "$label" "$(date +%Y%m%d-%H%M%S)"
}

show_check() {
  printf 'interface : %s\n' "$IF"
  printf 'ssid      : %s\n' "$(ssid_now)"
  printf 'bssid     : %s\n' "$(bssid_now)"
  printf 'address   : %s\n' "$(addr_now)"
  printf 'gateway   : %s\n' "$(gw_now)"
  printf 'mac       : %s\n' "$(mac_now)"
  printf 'signal    : %s dBm    tx-rate: %s\n' "$(signal_now)" "$(txrate_now)"
  printf 'optional  :'
  local t
  for t in iw iwgetid iwconfig nstat nmcli arping; do
    if have "$t"; then printf ' %s=yes' "$t"; else printf ' %s=NO' "$t"; fi
  done
  printf '\n'
}
