#!/usr/bin/env bash
set -euo pipefail

# =========================
# 可配置参数（可用环境变量覆盖）
# =========================
UPLINK_IF="${UPLINK_IF:-wlan0}"           # 上游联网接口（已连接路由器）
AP_IF="${AP_IF:-ap0}"                      # 热点接口（虚拟 AP）
SSID="${SSID:-z}"                          # 热点名
PASSPHRASE="${PASSPHRASE:-liuyucai}"       # 热点密码（至少 8 位）
AP_NET_CIDR="${AP_NET_CIDR:-10.88.0.1/24}" # 热点网关地址
AP_SUBNET="${AP_SUBNET:-10.88.0.0/24}"     # 热点网段（用于 NAT）

STATE_DIR="${STATE_DIR:-/run/wifi-share-ap}"
HOSTAPD_CONF="$STATE_DIR/hostapd.conf"
HOSTAPD_LOG="$STATE_DIR/hostapd.log"
HOSTAPD_PID="$STATE_DIR/hostapd.pid"
DNSMASQ_CONF="$STATE_DIR/dnsmasq.conf"
DNSMASQ_PID="$STATE_DIR/dnsmasq.pid"
DNSMASQ_LEASES="$STATE_DIR/dnsmasq.leases"

log() { printf '%s\n' "$*"; }
err() { printf 'error: %s\n' "$*" >&2; }

need_root() {
  if [[ ${EUID:-0} -ne 0 ]]; then
    err "请使用 sudo 运行"
    exit 1
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "缺少命令: $1"
    exit 1
  }
}

check_cmds() {
  need_cmd iw
  need_cmd ip
  need_cmd hostapd
  need_cmd dnsmasq
  need_cmd iptables
  need_cmd nmcli
}

get_channel() {
  local ch
  ch="$(iw dev "$UPLINK_IF" info 2>/dev/null | awk '/channel/{print $2; exit}')"
  [[ -n "$ch" ]] || {
    err "无法读取 $UPLINK_IF 当前信道，请先确认其已连接 Wi-Fi"
    exit 1
  }
  printf '%s' "$ch"
}

iface_exists() {
  iw dev "$1" info >/dev/null 2>&1
}

ensure_ap_iface() {
  if ! iface_exists "$AP_IF"; then
    iw dev "$UPLINK_IF" interface add "$AP_IF" type __ap
  fi
}

write_hostapd_conf() {
  local ch="$1"
  cat > "$HOSTAPD_CONF" <<EOF2
interface=$AP_IF
driver=nl80211
ssid=$SSID
hw_mode=g
channel=$ch
wmm_enabled=1
ieee80211n=1
country_code=CN
ieee80211d=1
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
wpa_passphrase=$PASSPHRASE
EOF2
}

write_dnsmasq_conf() {
  local gw
  gw="${AP_NET_CIDR%/*}"
  cat > "$DNSMASQ_CONF" <<EOF2
interface=$AP_IF
bind-dynamic
dhcp-range=10.88.0.10,10.88.0.200,255.255.255.0,12h
dhcp-option=3,$gw
dhcp-option=6,223.5.5.5,114.114.114.114
EOF2
}

iptables_add_once() {
  local table="$1"; shift
  if ! iptables -t "$table" -C "$@" 2>/dev/null; then
    iptables -t "$table" -A "$@"
  fi
}

iptables_del_if_exists() {
  local table="$1"; shift
  if iptables -t "$table" -C "$@" 2>/dev/null; then
    iptables -t "$table" -D "$@"
  fi
}

kill_by_pidfile() {
  local pidfile="$1"
  if [[ -f "$pidfile" ]]; then
    local pid
    pid="$(cat "$pidfile" 2>/dev/null || true)"
    if [[ -n "${pid:-}" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" || true
    fi
    rm -f "$pidfile"
  fi
}

wait_ap_ready() {
  local i
  for i in $(seq 1 30); do
    if iw dev "$AP_IF" info 2>/dev/null | grep -q 'type AP' &&
       ip link show "$AP_IF" 2>/dev/null | grep -q 'UP'; then
      return 0
    fi
    sleep 0.5
  done

  err "AP 接口未就绪（$AP_IF）"
  if [[ -f "$HOSTAPD_LOG" ]]; then
    echo "---- hostapd 日志 ----" >&2
    tail -n 80 "$HOSTAPD_LOG" >&2 || true
    echo "---------------------" >&2
  fi
  return 1
}

start_share() {
  need_root
  check_cmds

  mkdir -p "$STATE_DIR"

  ensure_ap_iface
  # 防止 NetworkManager 与 hostapd 抢占 AP 接口（接口创建后再次设置）
  nmcli dev set "$AP_IF" managed no >/dev/null 2>&1 || true

  local ch
  ch="$(get_channel)"
  write_hostapd_conf "$ch"
  write_dnsmasq_conf

  # 清理旧进程（仅清理本脚本相关实例）
  kill_by_pidfile "$HOSTAPD_PID"
  kill_by_pidfile "$DNSMASQ_PID"
  pkill -f "$HOSTAPD_CONF" 2>/dev/null || true
  pkill -f "$DNSMASQ_CONF" 2>/dev/null || true

  # 启动 hostapd（后台，并落日志）
  : > "$HOSTAPD_LOG"
  hostapd -B -f "$HOSTAPD_LOG" -P "$HOSTAPD_PID" "$HOSTAPD_CONF"
  wait_ap_ready

  # AP ready 后再配置地址，避免接口切换导致地址丢失
  ip addr replace "$AP_NET_CIDR" dev "$AP_IF"

  # 启动 dnsmasq（后台）
  dnsmasq --conf-file="$DNSMASQ_CONF" \
          --pid-file="$DNSMASQ_PID" \
          --dhcp-leasefile="$DNSMASQ_LEASES"

  # 打开转发 + NAT
  sysctl -w net.ipv4.ip_forward=1 >/dev/null
  iptables_add_once filter FORWARD -i "$AP_IF" -j ACCEPT
  iptables_add_once filter FORWARD -o "$AP_IF" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  iptables_add_once nat POSTROUTING -s "$AP_SUBNET" ! -o "$AP_IF" -j MASQUERADE

  log "共享已启动: $AP_IF -> $UPLINK_IF"
  log "SSID=$SSID, PASS=$PASSPHRASE, CH=$ch"
  log "网段=$AP_SUBNET 网关=${AP_NET_CIDR%/*}"
}

stop_share() {
  need_root
  check_cmds

  # 先停服务（仅处理本脚本实例）
  kill_by_pidfile "$HOSTAPD_PID"
  kill_by_pidfile "$DNSMASQ_PID"
  pkill -f "$HOSTAPD_CONF" 2>/dev/null || true
  pkill -f "$DNSMASQ_CONF" 2>/dev/null || true

  # 回收规则
  iptables_del_if_exists nat POSTROUTING -s "$AP_SUBNET" ! -o "$AP_IF" -j MASQUERADE
  iptables_del_if_exists filter FORWARD -i "$AP_IF" -j ACCEPT
  iptables_del_if_exists filter FORWARD -o "$AP_IF" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

  # 回收接口
  ip link set "$AP_IF" down 2>/dev/null || true
  iw dev "$AP_IF" del 2>/dev/null || true

  # 交还给 NM
  nmcli dev set "$AP_IF" managed yes >/dev/null 2>&1 || true

  rm -rf "$STATE_DIR"
  log "共享已停止"
}

status_share() {
  check_cmds

  echo "== Device =="
  nmcli -f DEVICE,TYPE,STATE,CONNECTION dev status | sed -n '1,20p'
  echo

  echo "== AP iface =="
  ip -4 addr show dev "$AP_IF" 2>/dev/null || echo "$AP_IF 不存在"
  echo

  echo "== Processes =="
  if [[ -f "$HOSTAPD_PID" ]] && kill -0 "$(cat "$HOSTAPD_PID")" 2>/dev/null; then
    echo "hostapd: running pid $(cat "$HOSTAPD_PID")"
  else
    echo "hostapd: stopped"
  fi
  if [[ -f "$DNSMASQ_PID" ]] && kill -0 "$(cat "$DNSMASQ_PID")" 2>/dev/null; then
    echo "dnsmasq: running pid $(cat "$DNSMASQ_PID")"
  else
    echo "dnsmasq: stopped"
  fi
  echo

  echo "== Leases =="
  [[ -f "$DNSMASQ_LEASES" ]] && cat "$DNSMASQ_LEASES" || echo "(none)"
  echo

  echo "== NAT rule =="
  iptables -t nat -S 2>/dev/null | grep "$AP_SUBNET" || echo "(none)"
}

usage() {
  cat <<EOF2
Usage: sudo $0 <start|stop|restart|status>

环境变量（可选）：
  UPLINK_IF, AP_IF, SSID, PASSPHRASE, AP_NET_CIDR, AP_SUBNET
EOF2
}

main() {
  case "${1:-}" in
    start) start_share ;;
    stop) stop_share ;;
    restart) stop_share || true; start_share ;;
    status) status_share ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"

# 中文注释：
# 1) 本脚本采用 iw + hostapd + dnsmasq + iptables，实现 wlan0 上网同时 ap0 开热点。
# 2) start 会自动读取 wlan0 当前信道并固定 AP 在同信道，避免并发冲突。
# 3) stop 会清理进程/规则/接口，恢复到未共享状态。
# 4) 若切到 5GHz 或信道变化，建议执行 restart 重新同步信道。
