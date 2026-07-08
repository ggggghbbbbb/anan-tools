#!/usr/bin/env bash
# 安安服务器工具箱 - 仿 kejilion 风格的常用项目菜单
# GitHub: https://github.com/ggggghbbbbb/anan-tools

set -o pipefail

VERSION="1.0.0"
SCRIPT_NAME="anan-tools"
BIN_PATH="/usr/local/bin/anan"
INSTALL_DIR="/opt/anan-tools"
TMP_DIR="/tmp/anan-tools"

C_RESET='\033[0m'
C_RED='\033[31m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_BLUE='\033[34m'
C_PURPLE='\033[35m'
C_CYAN='\033[96m'
C_WHITE='\033[97m'

# 可通过环境变量覆盖仓库地址，方便你后续换仓库或私有 fork
OCI_AI_REPO="${OCI_AI_REPO:-https://github.com/ggggghbbbbb/OCI-AI.git}"
OCI_PROXY_REPO="${OCI_PROXY_REPO:-https://github.com/ggggghbbbbb/OCI-IPv6-SOCKS5-PROXY.git}"

need_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo -e "${C_RED}请使用 root 用户运行，或加 sudo。${C_RESET}"
    exit 1
  fi
}

pause() {
  echo
  read -r -p "按回车返回菜单..." _
}

line() { echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"; }

header() {
  clear 2>/dev/null || true
  echo -e "${C_CYAN}"
  echo "   ___                    ______          __    "
  echo "  / _ | ___  ___ ____    /_  __/__  ___  / /____"
  echo " / __ |/ _ \/ _ \`/ _ \    / / / _ \/ _ \/ (_-<"
  echo "/_/ |_/ .__/\_,_/_//_/   /_/  \___/\___/_/___/"
  echo "     /_/                                       "
  echo -e "${C_RESET}"
  echo -e "${C_WHITE}安安服务器工具箱 v${VERSION}${C_RESET}"
  line
}

log() { echo -e "${C_GREEN}[OK]${C_RESET} $*"; }
warn() { echo -e "${C_YELLOW}[提示]${C_RESET} $*"; }
err() { echo -e "${C_RED}[错误]${C_RESET} $*"; }

cmd_exists() { command -v "$1" >/dev/null 2>&1; }

pm_detect() {
  if cmd_exists apt-get; then echo apt; return; fi
  if cmd_exists dnf; then echo dnf; return; fi
  if cmd_exists yum; then echo yum; return; fi
  if cmd_exists apk; then echo apk; return; fi
  if cmd_exists pacman; then echo pacman; return; fi
  echo unknown
}

pkg_update() {
  local pm; pm="$(pm_detect)"
  case "$pm" in
    apt) DEBIAN_FRONTEND=noninteractive apt-get update ;;
    dnf) dnf makecache -y ;;
    yum) yum makecache -y ;;
    apk) apk update ;;
    pacman) pacman -Sy --noconfirm ;;
    *) err "暂不支持当前包管理器"; return 1 ;;
  esac
}

pkg_upgrade() {
  local pm; pm="$(pm_detect)"
  case "$pm" in
    apt) DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y ;;
    dnf) dnf upgrade -y ;;
    yum) yum update -y ;;
    apk) apk update && apk upgrade ;;
    pacman) pacman -Syu --noconfirm ;;
    *) err "暂不支持当前包管理器"; return 1 ;;
  esac
}

pkg_install() {
  local pm; pm="$(pm_detect)"
  case "$pm" in
    apt) DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
    dnf) dnf install -y "$@" ;;
    yum) yum install -y "$@" ;;
    apk) apk add --no-cache "$@" ;;
    pacman) pacman -S --noconfirm --needed "$@" ;;
    *) err "暂不支持当前包管理器"; return 1 ;;
  esac
}

install_base_deps() {
  local miss=()
  for c in curl wget git tar gzip unzip ca-certificates; do
    cmd_exists "$c" || miss+=("$c")
  done
  if [ "${#miss[@]}" -gt 0 ]; then
    warn "安装缺失依赖：${miss[*]}"
    pkg_install "${miss[@]}"
  fi
}

system_info() {
  header
  echo -e "${C_PURPLE}系统信息${C_RESET}"
  line
  echo "主机名: $(hostname 2>/dev/null || echo '-')"
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo "系统: ${PRETTY_NAME:-unknown}"
  else
    echo "系统: unknown"
  fi
  echo "内核: $(uname -r)"
  echo "架构: $(uname -m)"
  echo "运行时间: $(uptime -p 2>/dev/null || uptime 2>/dev/null || echo '-')"
  echo "CPU: $(awk -F: '/model name/{print $2; exit}' /proc/cpuinfo 2>/dev/null | sed 's/^ *//' || echo '-')"
  echo "核心数: $(nproc 2>/dev/null || echo '-')"
  echo
  echo "内存:"
  free -h 2>/dev/null || true
  echo
  echo "磁盘:"
  df -hT / 2>/dev/null || true
  echo
  echo "公网 IP:"
  curl -4 -fsS --max-time 5 https://api.ipify.org 2>/dev/null | sed 's/^/IPv4: /' || echo "IPv4: 获取失败"
  curl -6 -fsS --max-time 5 https://api64.ipify.org 2>/dev/null | sed 's/^/IPv6: /' || echo "IPv6: 获取失败或无 IPv6"
}

system_update_menu() {
  while true; do
    header
    echo -e "${C_PURPLE}系统更新${C_RESET}"
    line
    echo "1. 更新软件源"
    echo "2. 更新系统软件包"
    echo "3. 安装基础依赖 curl/wget/git/unzip 等"
    echo "0. 返回主菜单"
    line
    if ! read -r -p "请选择: " n; then echo; exit 0; fi
    case "$n" in
      1) pkg_update; pause ;;
      2) pkg_upgrade; pause ;;
      3) install_base_deps; pause ;;
      0) break ;;
      *) warn "无效选择"; sleep 1 ;;
    esac
  done
}

common_software_menu() {
  while true; do
    header
    echo -e "${C_PURPLE}常用软件 / 项目${C_RESET}"
    line
    echo "1. OCI-AI 脚本"
    echo "2. OCI IPv6 SOCKS5 Proxy 代理池"
    echo "3. Docker / Docker Compose"
    echo "4. 常用命令行工具"
    echo "0. 返回主菜单"
    line
    if ! read -r -p "请选择: " n; then echo; exit 0; fi
    case "$n" in
      1) project_menu "OCI-AI" "$OCI_AI_REPO" "/opt/oci-ai" "oci-ai" "8321" ;;
      2) project_menu "OCI IPv6 SOCKS5 Proxy" "$OCI_PROXY_REPO" "/opt/oci-ipv6-socks5-proxy" "oci-ipv6-socks5-proxy" "18080" ;;
      3) docker_menu ;;
      4) cli_tools_menu ;;
      0) break ;;
      *) warn "无效选择"; sleep 1 ;;
    esac
  done
}

clone_or_update_repo() {
  local name="$1" repo="$2" dir="$3"
  install_base_deps
  mkdir -p "$(dirname "$dir")"
  if [ -d "$dir/.git" ]; then
    warn "$name 已存在，执行 git pull 更新"
    git -C "$dir" pull --ff-only
  else
    warn "克隆 $repo 到 $dir"
    rm -rf "$dir"
    git clone "$repo" "$dir"
  fi
}

find_install_script() {
  local dir="$1"
  for f in install.sh setup.sh deploy.sh run.sh main.sh start.sh; do
    [ -f "$dir/$f" ] && { echo "$dir/$f"; return 0; }
  done
  find "$dir" -maxdepth 2 -type f \( -name 'install*.sh' -o -name 'setup*.sh' -o -name 'deploy*.sh' \) 2>/dev/null | head -n1
}

run_project_install() {
  local name="$1" repo="$2" dir="$3"
  clone_or_update_repo "$name" "$repo" "$dir" || return 1
  local installer; installer="$(find_install_script "$dir")"
  if [ -n "$installer" ]; then
    warn "找到安装脚本：$installer"
    chmod +x "$installer"
    (cd "$dir" && bash "$installer")
  else
    warn "没有发现 install.sh/setup.sh 等安装脚本，已完成拉取：$dir"
    warn "你可以进入目录手动查看 README。"
  fi
}

run_project_update() {
  local name="$1" repo="$2" dir="$3"
  clone_or_update_repo "$name" "$repo" "$dir" || return 1
  local installer; installer="$(find_install_script "$dir")"
  if [ -n "$installer" ]; then
    if ! read -r -p "是否重新执行安装/部署脚本？[y/N]: " yn; then yn="N"; fi
    case "$yn" in
      y|Y) chmod +x "$installer"; (cd "$dir" && bash "$installer") ;;
      *) log "已只更新代码，未重新安装" ;;
    esac
  fi
}

run_project_uninstall() {
  local name="$1" dir="$2" service="$3"
  warn "准备卸载 $name"
  [ -n "$service" ] && systemctl list-unit-files 2>/dev/null | grep -q "^${service}\.service" && {
    systemctl stop "$service" 2>/dev/null || true
    systemctl disable "$service" 2>/dev/null || true
    rm -f "/etc/systemd/system/${service}.service"
    systemctl daemon-reload || true
  }
  if [ -d "$dir" ]; then
    if ! read -r -p "是否删除目录 $dir ? [y/N]: " yn; then yn="N"; fi
    case "$yn" in
      y|Y) rm -rf "$dir"; log "已删除 $dir" ;;
      *) warn "保留目录 $dir" ;;
    esac
  fi
}

open_firewall_port() {
  local port="$1"
  [ -z "$port" ] && { err "端口为空"; return 1; }
  warn "尝试放行端口 $port"
  if cmd_exists ufw; then ufw allow "$port/tcp" || true; fi
  if cmd_exists firewall-cmd; then firewall-cmd --permanent --add-port="${port}/tcp" && firewall-cmd --reload || true; fi
  if cmd_exists iptables; then iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -p tcp --dport "$port" -j ACCEPT || true; fi
  log "已尝试放行本机防火墙端口。云服务器安全组仍需在云平台后台放行。"
}

setup_domain_access() {
  local port="$1"
  header
  echo -e "${C_PURPLE}开启域名访问${C_RESET}"
  line
  echo "此功能会安装/配置 Caddy，把域名反代到本机端口 $port。"
  echo "要求：域名 A 记录已经解析到当前服务器 IP，云安全组放行 80/443。"
  echo
  if ! read -r -p "请输入域名（例如 ai.example.com，留空取消）: " domain; then domain=""; fi
  [ -z "$domain" ] && return 0
  install_caddy
  mkdir -p /etc/caddy
  if [ -f /etc/caddy/Caddyfile ]; then
    cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.bak.$(date +%Y%m%d%H%M%S)"
  fi
  cat >> /etc/caddy/Caddyfile <<EOF_CADDY

${domain} {
    reverse_proxy 127.0.0.1:${port}
}
EOF_CADDY
  systemctl enable --now caddy
  systemctl reload caddy || systemctl restart caddy
  open_firewall_port 80
  open_firewall_port 443
  log "域名访问已配置：https://${domain} -> 127.0.0.1:${port}"
}

install_caddy() {
  if cmd_exists caddy; then return 0; fi
  warn "安装 Caddy"
  local pm; pm="$(pm_detect)"
  case "$pm" in
    apt)
      pkg_install debian-keyring debian-archive-keyring apt-transport-https curl gpg
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
      DEBIAN_FRONTEND=noninteractive apt-get update
      DEBIAN_FRONTEND=noninteractive apt-get install -y caddy
      ;;
    dnf|yum) pkg_install 'dnf-command(copr)' || true; dnf copr enable -y @caddy/caddy || true; pkg_install caddy ;;
    *) pkg_install caddy ;;
  esac
}

project_status() {
  local dir="$1" service="$2" port="$3"
  header
  echo -e "${C_PURPLE}项目状态${C_RESET}"
  line
  echo "目录: $dir"
  if [ -d "$dir/.git" ]; then
    echo "仓库: $(git -C "$dir" remote get-url origin 2>/dev/null || echo '-')"
    echo "版本: $(git -C "$dir" rev-parse --short HEAD 2>/dev/null || echo '-')"
  else
    echo "仓库: 未拉取"
  fi
  echo
  if [ -n "$service" ]; then
    echo "服务: $service"
    local st
    st="$(systemctl is-active "$service" 2>/dev/null || true)"
    if [ -n "$st" ] && [ "$st" != "unknown" ]; then
      echo "状态: $st"
    else
      echo "状态: 未发现/未运行"
    fi
  fi
  if [ -n "$port" ]; then
    echo
    echo "端口监听:"
    ss -lntp 2>/dev/null | grep ":$port " || echo "未发现 $port 监听"
  fi
}

project_menu() {
  local name="$1" repo="$2" dir="$3" service="$4" port="$5"
  while true; do
    header
    echo -e "${C_PURPLE}${name}${C_RESET}"
    line
    echo "仓库: $repo"
    echo "目录: $dir"
    echo "端口: $port"
    line
    echo "1. 安装"
    echo "2. 卸载"
    echo "3. 更新"
    echo "4. 开启域名访问"
    echo "5. 查看状态"
    echo "6. 放行端口"
    echo "0. 返回上级菜单"
    line
    if ! read -r -p "请选择: " n; then echo; exit 0; fi
    case "$n" in
      1) run_project_install "$name" "$repo" "$dir"; pause ;;
      2) run_project_uninstall "$name" "$dir" "$service"; pause ;;
      3) run_project_update "$name" "$repo" "$dir"; pause ;;
      4) setup_domain_access "$port"; pause ;;
      5) project_status "$dir" "$service" "$port"; pause ;;
      6) open_firewall_port "$port"; pause ;;
      0) break ;;
      *) warn "无效选择"; sleep 1 ;;
    esac
  done
}

docker_menu() {
  while true; do
    header
    echo -e "${C_PURPLE}Docker / Docker Compose${C_RESET}"
    line
    echo "1. 安装 Docker"
    echo "2. 启动 Docker"
    echo "3. 查看 Docker 状态"
    echo "4. 卸载 Docker（保留数据）"
    echo "0. 返回上级菜单"
    line
    if ! read -r -p "请选择: " n; then echo; exit 0; fi
    case "$n" in
      1) install_docker; pause ;;
      2) systemctl enable --now docker; pause ;;
      3) docker --version 2>/dev/null || true; docker compose version 2>/dev/null || true; systemctl status docker --no-pager -l 2>/dev/null || true; pause ;;
      4) uninstall_docker; pause ;;
      0) break ;;
      *) warn "无效选择"; sleep 1 ;;
    esac
  done
}

install_docker() {
  if cmd_exists docker; then log "Docker 已安装"; return 0; fi
  warn "使用 Docker 官方脚本安装"
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sh /tmp/get-docker.sh
  systemctl enable --now docker
  log "Docker 安装完成"
}

uninstall_docker() {
  if ! read -r -p "确认卸载 Docker 软件包？不会删除 /var/lib/docker 数据。[y/N]: " yn; then yn="N"; fi
  case "$yn" in
    y|Y)
      local pm; pm="$(pm_detect)"
      systemctl stop docker 2>/dev/null || true
      case "$pm" in
        apt) DEBIAN_FRONTEND=noninteractive apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io docker-compose || true ;;
        dnf|yum) $pm remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker docker-compose || true ;;
        apk) apk del docker docker-cli-compose || true ;;
        pacman) pacman -Rns --noconfirm docker docker-compose || true ;;
      esac
      ;;
    *) warn "已取消" ;;
  esac
}

cli_tools_menu() {
  while true; do
    header
    echo -e "${C_PURPLE}常用命令行工具${C_RESET}"
    line
    echo "1. 安装常用工具包"
    echo "2. 安装/更新 uv"
    echo "3. 安装 Node.js LTS（NodeSource）"
    echo "0. 返回上级菜单"
    line
    if ! read -r -p "请选择: " n; then echo; exit 0; fi
    case "$n" in
      1) pkg_install curl wget git unzip zip tar gzip jq htop tmux nano vim ca-certificates openssl socat net-tools iproute2 dnsutils lsof ; pause ;;
      2) curl -LsSf https://astral.sh/uv/install.sh | sh; pause ;;
      3) install_node_lts; pause ;;
      0) break ;;
      *) warn "无效选择"; sleep 1 ;;
    esac
  done
}

install_node_lts() {
  if cmd_exists node; then warn "当前 Node: $(node -v)"; fi
  local pm; pm="$(pm_detect)"
  case "$pm" in
    apt)
      curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
      DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
      ;;
    dnf|yum)
      curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
      $pm install -y nodejs
      ;;
    *) pkg_install nodejs npm ;;
  esac
}

install_self() {
  need_root
  install_base_deps
  mkdir -p "$INSTALL_DIR"
  cp "$0" "$INSTALL_DIR/anan-tools.sh"
  chmod +x "$INSTALL_DIR/anan-tools.sh"
  ln -sf "$INSTALL_DIR/anan-tools.sh" "$BIN_PATH"
  log "已安装快捷命令：anan"
}

uninstall_self() {
  need_root
  rm -f "$BIN_PATH"
  if ! read -r -p "是否删除 $INSTALL_DIR ? [y/N]: " yn; then yn="N"; fi
  case "$yn" in y|Y) rm -rf "$INSTALL_DIR" ;; esac
  log "工具箱卸载完成"
}

self_update() {
  if [ -d "$INSTALL_DIR/.git" ]; then
    git -C "$INSTALL_DIR" pull --ff-only
    cp "$INSTALL_DIR/anan-tools.sh" "$BIN_PATH"
    chmod +x "$BIN_PATH"
  else
    warn "当前不是 git 安装目录。请用 GitHub 一键命令重新拉取最新版。"
  fi
}

main_menu() {
  need_root
  while true; do
    header
    echo "1. 系统信息"
    echo "2. 系统更新"
    echo "3. 常用软件"
    echo "4. 安装/刷新 anan 快捷命令"
    echo "5. 卸载本工具箱快捷命令"
    echo "0. 退出"
    line
    if ! read -r -p "请输入选项: " choice; then echo; exit 0; fi
    case "$choice" in
      1) system_info; pause ;;
      2) system_update_menu ;;
      3) common_software_menu ;;
      4) install_self; pause ;;
      5) uninstall_self; pause ;;
      0) echo "拜拜～"; exit 0 ;;
      *) warn "无效选择"; sleep 1 ;;
    esac
  done
}

case "${1:-}" in
  --version|-v) echo "$VERSION" ;;
  --install-self) install_self ;;
  --uninstall-self) uninstall_self ;;
  --system-info) system_info ;;
  --help|-h)
    echo "用法: $0 [--install-self|--uninstall-self|--system-info|--version]"
    ;;
  *) main_menu ;;
esac
