#!/usr/bin/env bash

set -u

detect_laptop_monitor() {
    hyprctl monitors all 2>/dev/null | awk '/^Monitor / {print $2}' | grep -E '^(eDP|LVDS|DSI)(-|$)' | head -n1
}

has_external_monitor() {
    local laptop_monitor="$1"
    hyprctl monitors 2>/dev/null | awk '/^Monitor / {print $2}' | grep -qv "^${laptop_monitor}$"
}

lid_is_closed() {
    local state_file
    for state_file in /proc/acpi/button/lid/*/state; do
        if [[ -r "$state_file" ]] && grep -qi "closed" "$state_file"; then
            return 0
        fi
    done
    return 1
}

apply_layout() {
    local laptop_monitor="$1"
    local desired_mode="$2"

    if [[ "$desired_mode" == "disable" ]]; then
        hyprctl keyword monitor "${laptop_monitor},disable" >/dev/null
    else
        hyprctl keyword monitor "${laptop_monitor},preferred,auto,1" >/dev/null
    fi
}

main() {
    local laptop_monitor
    laptop_monitor="$(detect_laptop_monitor || true)"

    # 没有检测到内屏时不做改动，避免误禁用显示器
    if [[ -z "${laptop_monitor}" ]]; then
        exit 0
    fi

    local last_mode=""
    while true; do
        local desired_mode="enable"
        if lid_is_closed && has_external_monitor "$laptop_monitor"; then
            desired_mode="disable"
        fi

        if [[ "$desired_mode" != "$last_mode" ]]; then
            apply_layout "$laptop_monitor" "$desired_mode"
            last_mode="$desired_mode"
        fi

        sleep 2
    done
}

main "$@"
