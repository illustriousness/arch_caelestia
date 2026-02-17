#!/usr/bin/env zsh

bootstrap_repo="$HOME/.local/share/caelestia"
bootstrap_script="$bootstrap_repo/install.zsh"
current_script="${0:A}"

if [[ "$current_script" != "$bootstrap_script" ]]; then
  if [[ ! -d "$bootstrap_repo/.git" ]]; then
    if [[ -e "$bootstrap_repo" ]]; then
      echo "Bootstrap failed: $bootstrap_repo exists but is not a git clone." >&2
      exit 1
    fi

    mkdir -p -- "$HOME/.local/share" || exit 1
    git clone https://github.com/illustriousness/caelestia.git "$bootstrap_repo" || exit 1
  fi

  cd "$bootstrap_repo" || exit 1
  exec zsh "$bootstrap_script" "$@"
fi

show_help() {
  echo 'usage: ./install.zsh [-h] [--noconfirm] [--spotify] [--vscode] [--discord] [--zen] [--aur-helper]'
  echo
  echo 'options:'
  echo '  -h, --help                  show this help message and exit'
  echo '  --noconfirm                 do not confirm package installation'
  echo '  --spotify                   install Spotify (Spicetify)'
  echo '  --vscode=[codium|code]      install VSCodium (or VSCode)'
  echo '  --discord                   install Discord (OpenAsar + Equicord)'
  echo '  --zen                       install Zen browser'
  echo '  --aur-helper=[yay|paru]     the AUR helper to use'
}

fail_invalid() {
  echo "$1" >&2
  exit 1
}

validate_choice() {
  local value="$1"
  shift
  local allowed
  for allowed in "$@"; do
    if [[ "$value" == "$allowed" ]]; then
      return 0
    fi
  done
  return 1
}

# Parsed flags
flag_help=0
flag_noconfirm=0
flag_spotify=0
flag_vscode=0
flag_discord=0
flag_zen=0
vscode_value="codium"
aur_helper="paru"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      flag_help=1
      shift
      ;;
    --noconfirm)
      flag_noconfirm=1
      shift
      ;;
    --spotify)
      flag_spotify=1
      shift
      ;;
    --discord)
      flag_discord=1
      shift
      ;;
    --zen)
      flag_zen=1
      shift
      ;;
    --vscode)
      flag_vscode=1
      if [[ -n "${2:-}" && "${2#-}" == "$2" ]]; then
        vscode_value="$2"
        shift 2
      else
        vscode_value="codium"
        shift
      fi
      validate_choice "$vscode_value" codium code || fail_invalid "Invalid --vscode value: $vscode_value (expected codium or code)"
      ;;
    --vscode=*)
      flag_vscode=1
      vscode_value="${1#*=}"
      [[ -z "$vscode_value" ]] && vscode_value="codium"
      validate_choice "$vscode_value" codium code || fail_invalid "Invalid --vscode value: $vscode_value (expected codium or code)"
      shift
      ;;
    --aur-helper)
      if [[ -n "${2:-}" && "${2#-}" == "$2" ]]; then
        aur_helper="$2"
        shift 2
      else
        aur_helper="paru"
        shift
      fi
      validate_choice "$aur_helper" yay paru || fail_invalid "Invalid --aur-helper value: $aur_helper (expected yay or paru)"
      ;;
    --aur-helper=*)
      aur_helper="${1#*=}"
      [[ -z "$aur_helper" ]] && aur_helper="paru"
      validate_choice "$aur_helper" yay paru || fail_invalid "Invalid --aur-helper value: $aur_helper (expected yay or paru)"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      fail_invalid "Unknown option: $1"
      ;;
    *)
      fail_invalid "Unexpected argument: $1"
      ;;
  esac
done

if [[ $# -gt 0 ]]; then
  fail_invalid "Unexpected argument: $1"
fi

if (( flag_help )); then
  show_help
  exit 0
fi

# Helper funcs
_out() {
  local colour="$1"
  local text="$2"
  shift 2

  local prefix reset
  case "$colour" in
    cyan)    prefix=$'\033[36m' ;;
    blue)    prefix=$'\033[34m' ;;
    magenta) prefix=$'\033[35m' ;;
    *)       prefix=$'\033[0m' ;;
  esac
  reset=$'\033[0m'

  printf '%s' "$prefix"
  if [[ "${1:-}" == "-n" ]]; then
    printf -- ':: %s' "$text"
  else
    printf -- ':: %s\n' "$text"
  fi
  printf '%s' "$reset"
}

log() {
  _out cyan "$1" "${@:2}"
}

input() {
  _out blue "$1" "${@:2}"
}

sh_read() {
  local value
  IFS= read -r value || return 1
  printf '%s' "$value"
}

backup_existing() {
  local path="$1"
  local backup_root="/home/lyc/.config/bak"
  local ts safe_name dest

  mkdir -p -- "$backup_root" || return 1

  ts="$(date +%Y%m%d-%H%M%S)"
  safe_name="${path#/}"
  safe_name="${safe_name//\//__}"
  dest="$backup_root/${safe_name}.${ts}"

  while [[ -e "$dest" || -L "$dest" ]]; do
    dest="$backup_root/${safe_name}.${ts}-$RANDOM"
  done

  mv -- "$path" "$dest" || return 1
  log "Backed up existing path to $dest"
  return 0
}

confirm_overwrite() {
  local path="$1"
  local confirm

  if [[ -e "$path" || -L "$path" ]]; then
    if (( flag_noconfirm )); then
      input "$path already exists. Overwrite? [Y/n]"
      log 'Moving existing path to backup...'
      backup_existing "$path" || {
        log 'Backup failed. Exiting...'
        exit 1
      }
    else
      input "$path already exists. Overwrite? [Y/n] " -n
      confirm="$(sh_read)" || exit 1
      echo

      if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
        log 'Skipping...'
        return 1
      else
        log 'Moving existing path to backup...'
        backup_existing "$path" || {
          log 'Backup failed. Exiting...'
          exit 1
        }
      fi
    fi
  fi

  return 0
}

# Variables
noconfirm_arg=()
(( flag_noconfirm )) && noconfirm_arg=(--noconfirm)
config="${XDG_CONFIG_HOME:-$HOME/.config}"
state="${XDG_STATE_HOME:-$HOME/.local/state}"

# Startup prompt
printf '\033[35m'
echo '╭─────────────────────────────────────────────────╮'
echo '│      ______           __          __  _         │'
echo '│     / ____/___ ____  / /__  _____/ /_(_)___ _   │'
echo '│    / /   / __ `/ _ \/ / _ \/ ___/ __/ / __ `/   │'
echo '│   / /___/ /_/ /  __/ /  __(__  ) /_/ / /_/ /    │'
echo '│   \____/\__,_/\___/_/\___/____/\__/_/\__,_/     │'
echo '│                                                 │'
echo '╰─────────────────────────────────────────────────╯'
printf '\033[0m'
log 'Welcome to the Caelestia dotfiles installer!'
log 'Before continuing, please ensure you have made a backup of your config directory.'

# Prompt for backup
if (( ! flag_noconfirm )); then
  log '[1] Two steps ahead of you!  [2] Make one for me please!'
  input '=> ' -n
  choice="$(sh_read)" || exit 1
  echo

  if [[ "$choice" == "1" || "$choice" == "2" ]]; then
    if [[ "$choice" == "2" ]]; then
      log "Backing up $config..."

      if [[ -e "$config.bak" || -L "$config.bak" ]]; then
        input 'Backup already exists. Overwrite? [Y/n] ' -n
        overwrite="$(sh_read)" || exit 1
        echo

        if [[ "$overwrite" == "n" || "$overwrite" == "N" ]]; then
          log 'Skipping...'
        else
          rm -rf -- "$config.bak"
          cp -r -- "$config" "$config.bak"
        fi
      else
        cp -r -- "$config" "$config.bak"
      fi
    fi
  else
    log 'No choice selected. Exiting...'
    exit 1
  fi
fi

# Install AUR helper if not already installed
if ! pacman -Q "$aur_helper" &>/dev/null; then
  log "$aur_helper not installed. Installing..."

  sudo pacman -S --needed git base-devel "${noconfirm_arg[@]}"
  cd /tmp || exit 1
  git clone "https://aur.archlinux.org/$aur_helper.git"
  cd "$aur_helper" || exit 1
  makepkg -si
  cd .. || exit 1
  rm -rf -- "$aur_helper"

  if [[ "$aur_helper" == "yay" ]]; then
    "$aur_helper" -Y --gendb
    "$aur_helper" -Y --devel --save
  else
    "$aur_helper" --gendb
  fi
fi

# Cd into dir
script_dir="$(cd -- "$(dirname -- "$0")" && pwd -P)"
cd "$script_dir" || exit 1

# Install metapackage for deps
log 'Installing metapackage...'
if [[ "$aur_helper" == "yay" ]]; then
  "$aur_helper" -Bi . "${noconfirm_arg[@]}"
else
  "$aur_helper" -Ui "${noconfirm_arg[@]}"
fi
rm -f -- caelestia-meta-*.pkg.tar.zst(N) 2>/dev/null

# Install hypr* configs
if confirm_overwrite "$config/hypr"; then
  log 'Installing hypr* configs...'
  ln -s -- "$(realpath hypr)" "$config/hypr"
  hyprctl reload
fi

# Starship
if confirm_overwrite "$config/starship.toml"; then
  log 'Installing starship config...'
  ln -s -- "$(realpath starship.toml)" "$config/starship.toml"
fi

# Foot
if confirm_overwrite "$config/foot"; then
  log 'Installing foot config...'
  ln -s -- "$(realpath foot)" "$config/foot"
fi

# Fish
if confirm_overwrite "$config/fish"; then
  log 'Installing fish config...'
  ln -s -- "$(realpath fish)" "$config/fish"
fi

# Fastfetch
if confirm_overwrite "$config/fastfetch"; then
  log 'Installing fastfetch config...'
  ln -s -- "$(realpath fastfetch)" "$config/fastfetch"
fi

# Uwsm
if confirm_overwrite "$config/uwsm"; then
  log 'Installing uwsm config...'
  ln -s -- "$(realpath uwsm)" "$config/uwsm"
fi

# Btop
if confirm_overwrite "$config/btop"; then
  log 'Installing btop config...'
  ln -s -- "$(realpath btop)" "$config/btop"
fi

# Install spicetify
if (( flag_spotify )); then
  log 'Installing spotify (spicetify)...'

  has_spicetify="$(pacman -Q spicetify-cli 2>/dev/null)"
  "$aur_helper" -S --needed spotify spicetify-cli spicetify-marketplace-bin "${noconfirm_arg[@]}"

  if [[ -z "$has_spicetify" ]]; then
    sudo chmod a+wr /opt/spotify
    sudo chmod a+wr /opt/spotify/Apps -R
    spicetify backup apply
  fi

  if confirm_overwrite "$config/spicetify"; then
    log 'Installing spicetify config...'
    ln -s -- "$(realpath spicetify)" "$config/spicetify"
    spicetify config current_theme caelestia color_scheme caelestia custom_apps marketplace 2>/dev/null
    spicetify apply
  fi
fi

# Install vscode
if (( flag_vscode )); then
  if [[ "$vscode_value" == "code" ]]; then
    prog='code'
    packages=(code)
    folder_name='Code'
  else
    prog='codium'
    packages=(vscodium-bin vscodium-bin-marketplace)
    folder_name='VSCodium'
  fi
  folder="$config/$folder_name/User"

  log "Installing vs$prog..."
  "$aur_helper" -S --needed "${packages[@]}" "${noconfirm_arg[@]}"

  if confirm_overwrite "$folder/settings.json" \
    && confirm_overwrite "$folder/keybindings.json" \
    && confirm_overwrite "$config/$prog-flags.conf"; then
    log "Installing vs$prog config..."
    ln -s -- "$(realpath vscode/settings.json)" "$folder/settings.json"
    ln -s -- "$(realpath vscode/keybindings.json)" "$folder/keybindings.json"
    ln -s -- "$(realpath vscode/flags.conf)" "$config/$prog-flags.conf"

    vsix_files=(vscode/caelestia-vscode-integration/caelestia-vscode-integration-*.vsix(N))
    if (( ${#vsix_files[@]} > 0 )); then
      "$prog" --install-extension "${vsix_files[1]}"
    else
      log 'No VSIX found. Skipping extension install...'
    fi
  fi
fi

# Install discord
if (( flag_discord )); then
  log 'Installing discord...'
  "$aur_helper" -S --needed discord equicord-installer-bin "${noconfirm_arg[@]}"

  sudo Equilotl -install -location /opt/discord
  sudo Equilotl -install-openasar -location /opt/discord

  "$aur_helper" -Rns equicord-installer-bin "${noconfirm_arg[@]}"
fi

# Install zen
if (( flag_zen )); then
  log 'Installing zen...'
  "$aur_helper" -S --needed zen-browser-bin "${noconfirm_arg[@]}"

  chrome_dirs=("$HOME"/.zen/*/chrome(N))
  if (( ${#chrome_dirs[@]} > 0 )); then
    chrome="${chrome_dirs[1]}"
    if confirm_overwrite "$chrome/userChrome.css"; then
      log 'Installing zen userChrome...'
      ln -s -- "$(realpath zen/userChrome.css)" "$chrome/userChrome.css"
    fi
  else
    log 'No Zen profile chrome directory found. Skipping userChrome install...'
  fi

  hosts="$HOME/.mozilla/native-messaging-hosts"
  lib="$HOME/.local/lib/caelestia"

  if confirm_overwrite "$hosts/caelestiafox.json"; then
    log 'Installing zen native app manifest...'
    mkdir -p -- "$hosts"
    cp -- zen/native_app/manifest.json "$hosts/caelestiafox.json"
    sed -i "s|{{ \$lib }}|$lib|g" "$hosts/caelestiafox.json"
  fi

  if confirm_overwrite "$lib/caelestiafox"; then
    log 'Installing zen native app...'
    mkdir -p -- "$lib"
    ln -s -- "$(realpath zen/native_app/app.fish)" "$lib/caelestiafox"
  fi

  log 'Please install the CaelestiaFox extension from https://addons.mozilla.org/en-US/firefox/addon/caelestiafox if you have not already done so.'
fi

# Generate scheme stuff if needed
if [[ ! -f "$state/caelestia/scheme.json" ]]; then
  caelestia scheme set -n shadotheme
  sleep 0.5
  hyprctl reload
fi

# Start the shell
caelestia shell -d >/dev/null

log 'Done!'
