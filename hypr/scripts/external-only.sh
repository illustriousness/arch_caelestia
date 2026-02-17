#!/usr/bin/env bash

set -u

poll_interval=2

detect_laptop_monitor() {
    local monitors_json="$1"
    jq -r 'map(select(.name | test("^(eDP|LVDS|DSI)(-|$)"))) | .[0].name // empty' <<<"$monitors_json"
}

has_external_monitor() {
    local monitors_json="$1"
    local laptop_monitor="$2"
    jq -e --arg laptop "$laptop_monitor" 'any(.[]; .name != $laptop and (.disabled // false | not))' <<<"$monitors_json" >/dev/null
}

laptop_monitor_is_disabled() {
    local monitors_json="$1"
    local laptop_monitor="$2"
    jq -e --arg laptop "$laptop_monitor" 'any(.[]; .name == $laptop and (.disabled // false))' <<<"$monitors_json" >/dev/null
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
    if ! command -v jq >/dev/null 2>&1; then
        echo "external-only.sh: jq is required but not found" >&2
        exit 1
    fi

    while true; do
        local monitors_json
        monitors_json="$(hyprctl -j monitors all 2>/dev/null || true)"
        if [[ -z "$monitors_json" ]] || ! jq -e 'type == "array"' >/dev/null 2>&1 <<<"$monitors_json"; then
            sleep "$poll_interval"
            continue
        fi

        local laptop_monitor
        laptop_monitor="$(detect_laptop_monitor "$monitors_json" || true)"
        if [[ -z "$laptop_monitor" ]]; then
            sleep "$poll_interval"
            continue
        fi

        local desired_mode="enable"
        if lid_is_closed && has_external_monitor "$monitors_json" "$laptop_monitor"; then
            desired_mode="disable"
        fi

        local current_mode="enable"
        if laptop_monitor_is_disabled "$monitors_json" "$laptop_monitor"; then
            current_mode="disable"
        fi

        if [[ "$desired_mode" != "$current_mode" ]]; then
            apply_layout "$laptop_monitor" "$desired_mode"
        fi

        sleep "$poll_interval"
    done
}

main "$@"
