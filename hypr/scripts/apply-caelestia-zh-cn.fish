#!/usr/bin/env fish

set -l repo_root (realpath (dirname (status filename))/../..)
set -l patch_file "$repo_root/hypr/patches/caelestia-shell-controlcenter-zh_CN.patch"
set -l source_dir /etc/xdg/quickshell/caelestia

set -l config_home "$HOME/.config"
if set -q XDG_CONFIG_HOME
    set config_home "$XDG_CONFIG_HOME"
end

set -l target_dir "$config_home/quickshell/caelestia"
set -l link_backup "$config_home/quickshell/caelestia.system-link.bak"

if not test -f "$patch_file"
    echo "Patch file not found: $patch_file"
    exit 1
end

if not test -d "$source_dir"
    echo "Source shell config not found: $source_dir"
    exit 1
end

if not test -d "$target_dir"
    mkdir -p (dirname "$target_dir")
    cp -a "$source_dir" "$target_dir"
    echo "Created user shell config at $target_dir"
end

# If target is symlinked to system config, replace with a user-local copy first.
if test -L "$target_dir"
    set -l resolved (realpath "$target_dir" 2>/dev/null)
    if test "$resolved" = "$source_dir"
        if test -e "$link_backup"
            echo "Backup already exists: $link_backup"
            echo "Please remove or rename it, then rerun."
            exit 1
        end
        mv "$target_dir" "$link_backup"
        cp -a "$source_dir" "$target_dir"
        echo "Replaced system symlink with user-local copy at $target_dir"
    end
end

if patch -d "$target_dir" -p1 --forward --dry-run --silent < "$patch_file" >/dev/null 2>/dev/null
    if patch -d "$target_dir" -p1 --forward --reject-file=- < "$patch_file"
        echo "Chinese patch applied successfully."
        echo "Restart shell with: pkill -f 'qs -c caelestia' && qs -c caelestia -n -d"
    else
        echo "Patch apply failed. Check write permissions for $target_dir"
        exit 1
    end
else if patch -d "$target_dir" -p1 --forward -R --dry-run --silent < "$patch_file" >/dev/null 2>/dev/null
    echo "Patch already applied."
    echo "Restart shell with: pkill -f 'qs -c caelestia' && qs -c caelestia -n -d"
else
    echo "Patch failed. The installed shell version may not match this patch."
    exit 1
end
