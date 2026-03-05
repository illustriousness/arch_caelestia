#!/usr/bin/env bash

set -euo pipefail

if ! command -v hyprctl >/dev/null 2>&1; then
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    notify-send -u normal "Window Picker" "jq 未安装，无法列出窗口"
    exit 1
fi

picker=""
if command -v wofi >/dev/null 2>&1; then
    picker="wofi"
elif command -v fuzzel >/dev/null 2>&1; then
    picker="fuzzel"
else
    notify-send -u normal "Window Picker" "未找到 wofi/fuzzel"
    exit 1
fi

clients_json="$(hyprctl clients -j)"
if [[ -z "${clients_json}" ]]; then
    exit 0
fi

entries="$(
    jq -r '
        map(select((.mapped // true) == true))
        | map({
            addr: .address,
            ws: (.workspace.id // -1),
            class: (.class // "unknown"),
            title: ((.title // "") | gsub("[\r\n\t]+"; " "))
        })
        | sort_by(.ws, .class, .title)
        | .[]
        | "\(.addr)\t[\(.ws)] \(.class) - \(
            if (.title | length) > 90 then
                (.title[0:87] + "...")
            else
                .title
            end
        )"
    ' <<<"${clients_json}"
)"

if [[ -z "${entries}" ]]; then
    notify-send -u low "Window Picker" "没有可选窗口"
    exit 0
fi

selection=""
display_entries="$(printf '%s\n' "${entries}" | cut -f2-)"
if [[ "${picker}" == "wofi" ]]; then
    selection="$(printf '%s\n' "${display_entries}" | wofi --dmenu --insensitive --prompt "Windows" --width 900 --height 520)" || true
else
    selection="$(printf '%s\n' "${display_entries}" | fuzzel --dmenu --prompt "Windows> ")" || true
fi

if [[ -z "${selection}" ]]; then
    exit 0
fi

addr="$(printf '%s\n' "${entries}" | awk -F'\t' -v selected="${selection}" '$2 == selected { print $1; exit }')"
if [[ -z "${addr}" ]]; then
    exit 0
fi

hyprctl dispatch focuswindow "address:${addr}" >/dev/null
