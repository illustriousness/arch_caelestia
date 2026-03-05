#!/usr/bin/env bash
set -euo pipefail

direction="${1:-next}"
case "$direction" in
  next|prev) ;;
  *) exit 0 ;;
esac

active_json="$(hyprctl -j activewindow 2>/dev/null || true)"
active_addr="$(jq -r '.address // empty' <<<"$active_json")"
workspace_id="$(jq -r '.workspace.id // empty' <<<"$active_json")"

if [[ -z "$active_addr" || -z "$workspace_id" || "$active_addr" == "null" || "$workspace_id" == "null" ]]; then
  exit 0
fi

mapfile -t windows < <(
  hyprctl -j clients \
    | jq -r --argjson ws "$workspace_id" '
        map(
          select(
            .workspace.id == $ws
            and .mapped == true
            and .hidden == false
          )
        )
        | sort_by(.at[0], .at[1], .address)
        | .[].address
      '
)

count="${#windows[@]}"
if (( count < 2 )); then
  exit 0
fi

current_index=-1
for i in "${!windows[@]}"; do
  if [[ "${windows[$i]}" == "$active_addr" ]]; then
    current_index="$i"
    break
  fi
done

if (( current_index < 0 )); then
  exit 0
fi

target_index="$current_index"
if [[ "$direction" == "next" ]]; then
  if (( current_index >= count - 1 )); then
    exit 0
  fi
  target_index=$((current_index + 1))
else
  if (( current_index <= 0 )); then
    exit 0
  fi
  target_index=$((current_index - 1))
fi

target_addr="${windows[$target_index]}"
if [[ -n "$target_addr" && "$target_addr" != "$active_addr" ]]; then
  hyprctl dispatch focuswindow "address:$target_addr" >/dev/null
fi
