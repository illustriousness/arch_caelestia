#!/usr/bin/env bash

set -euo pipefail

notify() {
    local urgency="$1"
    local message="$2"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" "Window Picker" "$message"
    fi
}

if ! command -v hyprctl >/dev/null 2>&1; then
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    notify normal "jq 未安装，无法列出窗口"
    exit 1
fi

picker=""
if command -v wofi >/dev/null 2>&1; then
    picker="wofi"
elif command -v fuzzel >/dev/null 2>&1; then
    picker="fuzzel"
else
    notify normal "未找到 wofi/fuzzel"
    exit 1
fi

clients_json="$(hyprctl -j clients 2>/dev/null || true)"
if [[ -z "$clients_json" ]] || ! jq -e 'type == "array"' >/dev/null 2>&1 <<<"$clients_json"; then
    exit 0
fi

rows_json="$(
    jq -c '
        map(
            select(
                (.mapped // true) == true
                and (.hidden // false) == false
                and (.workspace.id != null)
            )
        )
        | map({
            addr: .address,
            pid: (.pid // 0),
            ws: (.workspace.id // -1),
            class: (.class // "unknown"),
            initial_class: (.initialClass // ""),
            title: (
                (.title // "")
                | gsub("[\r\n\t]+"; " ")
                | gsub("^ +| +$"; "")
            )
        })
        | sort_by(.ws, .class, .title, .addr)
    ' <<<"$clients_json"
)"

row_count="$(jq 'length' <<<"$rows_json")"
if (( row_count == 0 )); then
    notify low "没有可选窗口"
    exit 0
fi

declare -A icon_name_cache=()
declare -A icon_path_cache=()

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/hypr-window-picker"
icon_name_cache_file="${cache_dir}/icon-name-cache.tsv"
icon_path_cache_file="${cache_dir}/icon-path-cache.tsv"

declare -a app_dirs=(
    "$HOME/.local/share/applications"
    "/usr/local/share/applications"
    "/usr/share/applications"
)

mkdir -p "$cache_dir"

load_icon_name_cache() {
    local key
    local value

    [[ -r "$icon_name_cache_file" ]] || return 0
    while IFS=$'\t' read -r key value; do
        [[ -n "$key" ]] || continue
        icon_name_cache["$key"]="$value"
    done <"$icon_name_cache_file"
}

load_icon_path_cache() {
    local key
    local value

    [[ -r "$icon_path_cache_file" ]] || return 0
    while IFS=$'\t' read -r key value; do
        [[ -n "$key" ]] || continue
        icon_path_cache["$key"]="$value"
    done <"$icon_path_cache_file"
}

save_icon_name_cache() {
    local tmp
    local key
    tmp="${icon_name_cache_file}.tmp.$$"
    : >"$tmp"
    for key in "${!icon_name_cache[@]}"; do
        printf '%s\t%s\n' "$key" "${icon_name_cache[$key]}" >>"$tmp"
    done
    mv "$tmp" "$icon_name_cache_file"
}

save_icon_path_cache() {
    local tmp
    local key
    tmp="${icon_path_cache_file}.tmp.$$"
    : >"$tmp"
    for key in "${!icon_path_cache[@]}"; do
        printf '%s\t%s\n' "$key" "${icon_path_cache[$key]}" >>"$tmp"
    done
    mv "$tmp" "$icon_path_cache_file"
}

desktop_name_candidates() {
    local key="$1"
    local lower="${key,,}"

    printf '%s\n' \
        "$key" \
        "$lower" \
        "${key// /-}" \
        "${lower// /-}" \
        "${key// /_}" \
        "${lower// /_}" \
        "${key//./-}" \
        "${lower//./-}"
}

read_icon_from_desktop() {
    local file="$1"
    awk -F= '
        BEGIN { in_entry = 0 }
        /^\[Desktop Entry\]$/ { in_entry = 1; next }
        /^\[/ { if (in_entry) exit; next }
        !in_entry { next }
        /^Icon=/ {
            value = substr($0, index($0, "=") + 1)
            if (value != "") {
                print value
                exit
            }
        }
    ' "$file"
}

find_desktop_file_by_basename() {
    local key="$1"
    local dir
    local name
    local path

    while IFS= read -r name; do
        [[ -n "$name" ]] || continue
        for dir in "${app_dirs[@]}"; do
            path="${dir}/${name}.desktop"
            if [[ -f "$path" ]]; then
                printf '%s\n' "$path"
                return 0
            fi
        done
    done < <(desktop_name_candidates "$key")

    return 1
}

find_desktop_file_by_wmclass() {
    local key="$1"
    local dir
    local path=""

    for dir in "${app_dirs[@]}"; do
        [[ -d "$dir" ]] || continue
        if command -v rg >/dev/null 2>&1; then
            path="$(
                rg -l -m 1 -F --glob '*.desktop' \
                    -e "StartupWMClass=$key" \
                    -e "X-GNOME-WMClass=$key" \
                    "$dir" 2>/dev/null | head -n 1
            )"
        else
            path="$(
                grep -R -m 1 -l -F --include='*.desktop' \
                    -e "StartupWMClass=$key" \
                    -e "X-GNOME-WMClass=$key" \
                    "$dir" 2>/dev/null | head -n 1
            )"
        fi

        if [[ -n "$path" ]]; then
            printf '%s\n' "$path"
            return 0
        fi
    done

    return 1
}

resolve_icon_name_for_key() {
    local key="$1"
    local cache_key="${key,,}"
    local cached="${icon_name_cache[$cache_key]:-}"
    local file
    local icon=""

    if [[ -n "$cached" ]]; then
        if [[ "$cached" == "__none__" ]]; then
            return 1
        fi
        printf '%s\n' "$cached"
        return 0
    fi

    file="$(find_desktop_file_by_basename "$key" || true)"
    if [[ -z "$file" ]]; then
        file="$(find_desktop_file_by_wmclass "$key" || true)"
    fi

    if [[ -n "$file" ]]; then
        icon="$(read_icon_from_desktop "$file" || true)"
    fi

    if [[ -n "$icon" ]]; then
        icon_name_cache["$cache_key"]="$icon"
        printf '%s\n' "$icon"
        return 0
    fi

    icon_name_cache["$cache_key"]="__none__"
    return 1
}

find_icon_name() {
    local class="$1"
    local initial_class="$2"
    local key
    local icon

    for key in "$class" "$initial_class"; do
        [[ -n "$key" ]] || continue
        if icon="$(resolve_icon_name_for_key "$key" || true)"; then
            [[ -n "$icon" ]] || continue
            printf '%s\n' "$icon"
            return 0
        fi
    done

    return 1
}

resolve_icon_path() {
    local icon_name="$1"
    local normalized
    local candidate
    local path

    [[ -n "$icon_name" ]] || return 1

    if [[ -n "${icon_path_cache[$icon_name]:-}" ]]; then
        if [[ "${icon_path_cache[$icon_name]}" == "__none__" ]]; then
            return 1
        fi
        printf '%s\n' "${icon_path_cache[$icon_name]}"
        return 0
    fi

    normalized="$icon_name"
    normalized="${normalized%.png}"
    normalized="${normalized%.svg}"
    normalized="${normalized%.xpm}"

    path=""

    if [[ "$icon_name" == /* && -f "$icon_name" ]]; then
        path="$icon_name"
    elif [[ -f "$icon_name" ]]; then
        path="$icon_name"
    else
        for candidate in \
            "/usr/share/pixmaps/${normalized}.png" \
            "/usr/share/pixmaps/${normalized}.svg" \
            "/usr/share/pixmaps/${normalized}.xpm" \
            "$HOME/.local/share/icons/${normalized}.png" \
            "$HOME/.local/share/icons/${normalized}.svg" \
            "$HOME/.local/share/icons/${normalized}.xpm" \
            "$HOME/.icons/${normalized}.png" \
            "$HOME/.icons/${normalized}.svg" \
            "$HOME/.icons/${normalized}.xpm"; do
            if [[ -f "$candidate" ]]; then
                path="$candidate"
                break
            fi
        done

        if [[ -z "$path" ]]; then
            path="$(
                find \
                    "$HOME/.local/share/icons" \
                    "$HOME/.icons" \
                    /usr/local/share/icons \
                    /usr/share/icons \
                    /usr/share/pixmaps \
                    -type f \
                    \( -iname "${normalized}.png" -o -iname "${normalized}.svg" -o -iname "${normalized}.xpm" \) \
                    2>/dev/null \
                    | head -n 1
            )"
        fi
    fi

    if [[ -z "$path" ]]; then
        icon_path_cache["$icon_name"]="__none__"
        return 1
    fi

    icon_path_cache["$icon_name"]="$path"
    printf '%s\n' "$path"
}

if [[ "$picker" == "wofi" ]]; then
    load_icon_name_cache
    load_icon_path_cache
fi

declare -a addrs=()
declare -a display_texts=()
declare -a menu_lines=()

while IFS=$'\t' read -r addr pid ws class initial_class title; do
    [[ -n "$addr" ]] || continue
    if [[ "$pid" =~ ^[0-9]+$ ]] && (( pid > 1 )) && [[ ! -d "/proc/$pid" ]]; then
        continue
    fi
    raw_class="$class"

    if [[ -z "$title" ]]; then
        title="$class"
    fi

    # Wofi image escape uses ':' as separator, avoid accidental token splits.
    title="${title//:/ - }"
    class="${class//:/ - }"

    display="[${ws}] ${class} - ${title}"
    if (( ${#display} > 120 )); then
        display="${display:0:117}..."
    fi

    menu_line="$display"
    if [[ "$picker" == "wofi" ]]; then
        icon_name="$(find_icon_name "$raw_class" "$initial_class" || true)"
        icon_path=""
        if [[ -n "$icon_name" ]]; then
            icon_path="$(resolve_icon_path "$icon_name" || true)"
        fi

        if [[ -n "$icon_path" ]]; then
            menu_line="img:${icon_path}:text:${display}"
        else
            menu_line="text:${display}"
        fi
    fi

    addrs+=("$addr")
    display_texts+=("$display")
    menu_lines+=("$menu_line")
done < <(
    jq -r '
        .[]
        | [.addr, (.pid | tostring), (.ws | tostring), .class, .initial_class, .title]
        | @tsv
    ' <<<"$rows_json"
)

if [[ "$picker" == "wofi" ]]; then
    save_icon_name_cache
    save_icon_path_cache
fi

if (( ${#addrs[@]} == 0 )); then
    notify low "没有可选窗口"
    exit 0
fi

selection=""
if [[ "$picker" == "wofi" ]]; then
    selection="$(
        printf '%s\n' "${menu_lines[@]}" \
            | wofi \
                --dmenu \
                --allow-images \
                --insensitive \
                --prompt "Windows" \
                --width 1000 \
                --height 560 \
                --lines 20 \
                --no-custom-entry \
                -D dmenu-print_line_num=true \
                -D dmenu-parse_action=true
    )" || true
else
    selection="$(printf '%s\n' "${menu_lines[@]}" | fuzzel --dmenu --prompt "Windows> ")" || true
fi

if [[ -z "$selection" ]]; then
    exit 0
fi

target_index="-1"
if [[ "$selection" =~ ^[0-9]+$ ]]; then
    target_index="$selection"
else
    for i in "${!display_texts[@]}"; do
        if [[ "${display_texts[$i]}" == "$selection" ]]; then
            target_index="$i"
            break
        fi
    done
fi

if (( target_index < 0 || target_index >= ${#addrs[@]} )); then
    exit 0
fi

hyprctl dispatch "hl.dsp.focus({ window = \"address:${addrs[$target_index]}\" })" >/dev/null
