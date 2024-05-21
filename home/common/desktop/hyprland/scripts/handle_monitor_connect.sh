# shellcheck shell=bash
# minimum number of workspaces across all monitors
MIN_WORKSPACES=8

function assign_workspaces {

  ((n_mon = $(hyprctl monitors -j | jq "length"))) || true
  ((wksp_per_mon = MIN_WORKSPACES / n_mon)) || true

  for mntr_idx in $(seq 0 $n_mon); do
    ((start = mntr_idx * wksp_per_mon + 1)) || true
    ((end = start + wksp_per_mon)) || true
    for wksp_idx in $(seq $start $end); do
      echo "Mapping workspace: $wksp_idx -> Monitor $mntr_idx"
      hyprctl dispatch moveworkspacetomonitor "$wksp_idx $mntr_idx"
    done
  done
}

function handle {
  if [[ ${1:0:12} == "monitoradded" || ${1:0:14} == "monitorremoved" ]]; then
    assign_workspaces
  fi
}

# run this once for startup
assign_workspaces

socat - "UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
