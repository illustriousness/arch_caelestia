#!/usr/bin/env bash

set -u

scheme_path="${CAELESTIA_SCHEME_PATH:-$HOME/.local/state/caelestia/scheme.json}"
tabby_path="${TABBY_CONFIG_PATH:-$HOME/.config/tabby/config.yaml}"

apply_tabby_theme() {
    local scheme="$1"
    local tabby="$2"

    if [[ ! -f "$scheme" || ! -f "$tabby" ]]; then
        return 0
    fi

    python - "$scheme" "$tabby" <<'PY'
import json
import sys
from pathlib import Path

try:
    import yaml
except Exception:
    raise SystemExit(0)

scheme_path = Path(sys.argv[1])
tabby_path = Path(sys.argv[2])

try:
    scheme = json.loads(scheme_path.read_text())
    colours = scheme["colours"]
except Exception:
    raise SystemExit(0)

required = ["onSurface", "surface", "secondary", *[f"term{i}" for i in range(16)]]
if any(key not in colours for key in required):
    raise SystemExit(0)

try:
    cfg = yaml.safe_load(tabby_path.read_text()) or {}
except Exception:
    raise SystemExit(0)

terminal = cfg.setdefault("terminal", {})
palette = [f"#{colours[f'term{i}']}" for i in range(16)]
foreground = f"#{colours['onSurface']}"
background = f"#{colours['surface']}"
cursor = f"#{colours['secondary']}"

for key, name in (
    ("colorScheme", "Caelestia Auto"),
    ("lightColorScheme", "Caelestia Auto Light"),
):
    scheme_block = terminal.setdefault(key, {})
    scheme_block["name"] = name
    scheme_block["foreground"] = foreground
    scheme_block["background"] = background
    scheme_block["cursor"] = cursor
    scheme_block["colors"] = list(palette)

updated = yaml.safe_dump(cfg, sort_keys=False, allow_unicode=True, default_flow_style=False)
current = tabby_path.read_text()
if updated != current:
    tabby_path.write_text(updated)
PY
}

if [[ "${1:-}" == "--watch" ]]; then
    apply_tabby_theme "$scheme_path" "$tabby_path"

    last_mtime=""
    while true; do
        if [[ -f "$scheme_path" ]]; then
            mtime="$(stat -c %Y "$scheme_path" 2>/dev/null || true)"
            if [[ -n "$mtime" && "$mtime" != "$last_mtime" ]]; then
                last_mtime="$mtime"
                apply_tabby_theme "$scheme_path" "$tabby_path"
            fi
        fi
        sleep 1
    done
else
    apply_tabby_theme "$scheme_path" "$tabby_path"
fi
