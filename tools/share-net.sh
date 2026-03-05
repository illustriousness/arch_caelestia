#!/usr/bin/env bash
set -euo pipefail

LAN_IF="${LAN_IF:-enp3s0}"
LAN_ADDR="${LAN_ADDR:-192.168.137.1/24}"
NM_CON_NAME="${NM_CON_NAME:-share-lan}"

log() { printf '%s\n' "$*"; }
die() { log "error: $*"; exit 1; }

usage() {
  cat <<USAGE
Usage: sudo $0 <start|stop|restart|status>

可选环境变量:
  LAN_IF       局域网口（默认: enp3s0）
  LAN_ADDR     局域网地址（默认: 192.168.137.1/24）
  NM_CON_NAME  连接名（默认: share-lan）
USAGE
}

require_root() {
  if [[ ${EUID:-0} -ne 0 ]]; then
    die "请使用 sudo 运行"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "缺少命令: $1"
}

# 按“连接名 + 接口名”精确找 UUID，避免同名连接歧义。
find_con_uuid() {
  local name uuid iface
  while IFS=: read -r name uuid; do
    [[ "$name" == "$NM_CON_NAME" ]] || continue
    iface="$(nmcli -g connection.interface-name con show "$uuid" 2>/dev/null || true)"
    if [[ "$iface" == "$LAN_IF" ]]; then
      printf '%s\n' "$uuid"
      return 0
    fi
  done < <(nmcli -t -f NAME,UUID con show)
  return 1
}

# 删除同名但非目标接口的重复配置，保证后续操作稳定。
cleanup_duplicate_name() {
  local target_uuid="${1:-}" name uuid iface
  while IFS=: read -r name uuid; do
    [[ "$name" == "$NM_CON_NAME" ]] || continue
    [[ -n "$target_uuid" && "$uuid" == "$target_uuid" ]] && continue
    iface="$(nmcli -g connection.interface-name con show "$uuid" 2>/dev/null || true)"
    if [[ "$iface" != "$LAN_IF" ]]; then
      nmcli con delete uuid "$uuid" >/dev/null 2>&1 || true
    fi
  done < <(nmcli -t -f NAME,UUID con show)
}

start_share() {
  require_root
  require_cmd nmcli

  local uuid
  uuid="$(find_con_uuid || true)"

  if [[ -z "$uuid" ]]; then
    nmcli con add type ethernet ifname "$LAN_IF" con-name "$NM_CON_NAME" >/dev/null
    uuid="$(find_con_uuid || true)"
  fi

  [[ -n "$uuid" ]] || die "无法创建或定位连接: $NM_CON_NAME ($LAN_IF)"
  cleanup_duplicate_name "$uuid"

  nmcli con mod uuid "$uuid" \
    connection.id "$NM_CON_NAME" \
    connection.interface-name "$LAN_IF" \
    connection.autoconnect yes \
    ipv4.method shared \
    ipv4.addresses "$LAN_ADDR" \
    ipv6.method ignore

  nmcli con up uuid "$uuid"
  log "共享已开启: ${LAN_IF} (${LAN_ADDR})"
}

stop_share() {
  require_root
  require_cmd nmcli

  local uuid
  uuid="$(find_con_uuid || true)"
  if [[ -z "$uuid" ]]; then
    log "连接 '$NM_CON_NAME'($LAN_IF) 不存在，无需停止"
    return 0
  fi

  nmcli con down uuid "$uuid" || true
  nmcli con mod uuid "$uuid" connection.autoconnect no
  cleanup_duplicate_name "$uuid"
  log "共享已停止: $NM_CON_NAME ($LAN_IF)"
}

status_share() {
  require_cmd nmcli

  local uuid
  uuid="$(find_con_uuid || true)"
  if [[ -z "$uuid" ]]; then
    log "连接 '$NM_CON_NAME'($LAN_IF) 不存在"
    return 0
  fi

  nmcli -f connection.id,connection.uuid,connection.interface-name,connection.autoconnect,ipv4.method,ipv4.addresses,ipv6.method con show uuid "$uuid"
  echo "---"
  nmcli -f GENERAL.DEVICE,GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY device show "$LAN_IF" || true
}

cmd="${1:-}"
case "$cmd" in
  start)
    start_share
    ;;
  stop)
    stop_share
    ;;
  restart)
    stop_share
    start_share
    ;;
  status)
    status_share
    ;;
  *)
    usage
    exit 1
    ;;
esac

# 中文注释：
# 1) 本脚本仅使用 NetworkManager（nmcli）进行共享，不再使用 iptables/dnsmasq。
# 2) start: 将 LAN_IF 对应连接设置为 ipv4.method shared 并启动。
# 3) stop: 下线该连接并关闭 autoconnect，不删除主配置。
# 4) 为防止“同名连接”冲突，脚本按 UUID+接口匹配，并自动清理无关重复项。
# 5) 共享出口由系统默认路由决定（例如 wlan0 或其他已联网接口）。
