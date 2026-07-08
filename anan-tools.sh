#!/usr/bin/env bash
# anan 脚本工具箱 - 菜单式服务器管理与个人软件仓库
# GitHub: https://github.com/ggggghbbbbb/anan-tools

set -o pipefail

VERSION="1.1.0"
SCRIPT_NAME="anan-tools"
DEFAULT_SHORTCUT="a"
BIN_PATH="/usr/local/bin/${DEFAULT_SHORTCUT}"
ALT_BIN_PATH="/usr/local/bin/anan"
INSTALL_DIR="/opt/anan-tools"
REPO_RAW="https://raw.githubusercontent.com/ggggghbbbbb/anan-tools/main/anan-tools.sh"
REPO_GIT="https://github.com/ggggghbbbbb/anan-tools.git"

# 以后你单独存放的软件/项目仓库入口，默认先放这两个
OCI_AI_REPO="${OCI_AI_REPO:-https://github.com/ggggghbbbbb/OCI-AI.git}"
OCI_PROXY_REPO="${OCI_PROXY_REPO:-https://github.com/ggggghbbbbb/OCI-IPv6-SOCKS5-PROXY.git}"

C_RESET='\033[0m'; C_RED='\033[31m'; C_GREEN='\033[32m'; C_YELLOW='\033[33m'
C_BLUE='\033[34m'; C_PURPLE='\033[35m'; C_CYAN='\033[96m'; C_WHITE='\033[97m'; C_GRAY='\033[90m'

need_root() { [ "${EUID:-$(id -u)}" -eq 0 ] || { echo -e "${C_RED}请使用 root 用户运行，或加 sudo。${C_RESET}"; exit 1; }; }
cmd_exists() { command -v "$1" >/dev/null 2>&1; }
line() { echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"; }
small_line() { echo -e "${C_GRAY}────────────────────────────────────────────────────${C_RESET}"; }
pause() { echo; read -r -p "按回车返回菜单..." _ || true; }
log() { echo -e "${C_GREEN}[OK]${C_RESET} $*"; }
warn() { echo -e "${C_YELLOW}[提示]${C_RESET} $*"; }
err() { echo -e "${C_RED}[错误]${C_RESET} $*"; }
ask() { local __v="$1" __p="$2"; if ! read -r -p "$__p" "$__v"; then printf -v "$__v" ''; fi; }
confirm() { local y; ask y "$1 [y/N]: "; [[ "$y" =~ ^[Yy]$ ]]; }

header() {
  clear 2>/dev/null || true
  echo -e "${C_CYAN}"
  echo "        ✿  anan 脚本工具箱  ✿"
  echo "  ╔═╗ ╔╗╔ ╔═╗ ╔╗╔    ╔╦╗ ╔═╗ ╔═╗ ╦  ╔═╗"
  echo "  ╠═╣ ║║║ ╠═╣ ║║║     ║  ║ ║ ║ ║ ║  ╚═╗"
  echo "  ╩ ╩ ╝╚╝ ╩ ╩ ╝╚╝     ╩  ╚═╝ ╚═╝ ╩═╝╚═╝"
  echo -e "${C_RESET}"
  echo -e "${C_WHITE}anan 脚本工具箱 v${VERSION}${C_RESET}"
  echo -e "${C_YELLOW}命令行输入 ${DEFAULT_SHORTCUT} 可快速进入脚本${C_RESET}"
  line
}

pm_detect() {
  if cmd_exists apt-get; then echo apt; elif cmd_exists dnf; then echo dnf; elif cmd_exists yum; then echo yum; elif cmd_exists apk; then echo apk; elif cmd_exists pacman; then echo pacman; else echo unknown; fi
}

pkg_update() { case "$(pm_detect)" in apt) DEBIAN_FRONTEND=noninteractive apt-get update;; dnf) dnf makecache -y;; yum) yum makecache -y;; apk) apk update;; pacman) pacman -Sy --noconfirm;; *) err "暂不支持当前包管理器"; return 1;; esac; }
pkg_upgrade() { case "$(pm_detect)" in apt) DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y;; dnf) dnf upgrade -y;; yum) yum update -y;; apk) apk update && apk upgrade;; pacman) pacman -Syu --noconfirm;; *) err "暂不支持当前包管理器"; return 1;; esac; }
pkg_install() { case "$(pm_detect)" in apt) DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y "$@";; dnf) dnf install -y "$@";; yum) yum install -y "$@";; apk) apk add --no-cache "$@";; pacman) pacman -S --noconfirm --needed "$@";; *) err "暂不支持当前包管理器"; return 1;; esac; }
pkg_remove() { case "$(pm_detect)" in apt) DEBIAN_FRONTEND=noninteractive apt-get remove -y "$@";; dnf|yum) "$(pm_detect)" remove -y "$@";; apk) apk del "$@";; pacman) pacman -Rns --noconfirm "$@";; *) err "暂不支持当前包管理器"; return 1;; esac; }
install_base_deps() { local miss=(); for c in curl wget git tar gzip unzip ca-certificates; do cmd_exists "$c" || miss+=("$c"); done; [ ${#miss[@]} -eq 0 ] || pkg_install "${miss[@]}"; }

system_info() {
  header; echo -e "${C_PURPLE}系统信息查询${C_RESET}"; small_line
  echo "主机名: $(hostname 2>/dev/null || echo '-')"
  if [ -r /etc/os-release ]; then . /etc/os-release; echo "系统: ${PRETTY_NAME:-unknown}"; else echo "系统: unknown"; fi
  echo "内核: $(uname -r)"; echo "架构: $(uname -m)"; echo "运行时间: $(uptime -p 2>/dev/null || uptime 2>/dev/null || echo '-')"
  echo "CPU: $(awk -F: '/model name/{print $2; exit}' /proc/cpuinfo 2>/dev/null | sed 's/^ *//' || echo '-')"; echo "核心数: $(nproc 2>/dev/null || echo '-')"
  echo; echo -e "${C_CYAN}内存:${C_RESET}"; free -h 2>/dev/null || true
  echo; echo -e "${C_CYAN}磁盘:${C_RESET}"; df -hT / 2>/dev/null || true
  echo; echo -e "${C_CYAN}公网 IP:${C_RESET}"; curl -4 -fsS --max-time 5 https://api.ipify.org 2>/dev/null | sed 's/^/IPv4: /' || echo "IPv4: 获取失败"; echo
  curl -6 -fsS --max-time 5 https://api64.ipify.org 2>/dev/null | sed 's/^/IPv6: /' || echo "IPv6: 获取失败或无 IPv6"
}

linux_clean() {
  header; echo -e "${C_PURPLE}系统清理${C_RESET}"; small_line
  case "$(pm_detect)" in
    apt) apt-get autoremove -y || true; apt-get autoclean -y || true; apt-get clean || true;;
    dnf|yum) "$(pm_detect)" autoremove -y || true; "$(pm_detect)" clean all || true;;
    apk) rm -rf /var/cache/apk/*;;
    pacman) pacman -Sc --noconfirm || true;;
  esac
  journalctl --vacuum-time=7d 2>/dev/null || true
  rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
  log "清理完成"
}

system_update_menu() {
  while true; do header; echo -e "${C_PURPLE}系统更新${C_RESET}"; small_line
    echo "1. 更新软件源"; echo "2. 更新系统软件包"; echo "3. 安装基础依赖 curl/wget/git/unzip 等"; echo "0. 返回主菜单"; line
    if ! read -r -p "请选择: " n; then exit 0; fi
    case "$n" in 1) pkg_update; pause;; 2) pkg_upgrade; pause;; 3) install_base_deps; pause;; 0) break;; *) warn "无效选择"; sleep 1;; esac
  done
}

# 软件仓库：以后你自己的项目都放这里，Docker 和基础工具已单独摘到主菜单
software_repo_menu() {
  while true; do header; echo -e "${C_PURPLE}我的软件仓库${C_RESET}"; small_line
    echo "1. OCI-AI 脚本"; echo "2. OCI IPv6 SOCKS5 Proxy 代理池"; echo "3. 自定义 GitHub 项目拉取/安装"; echo "0. 返回主菜单"; line
    if ! read -r -p "请选择: " n; then exit 0; fi
    case "$n" in
      1) project_menu "OCI-AI" "$OCI_AI_REPO" "/opt/oci-ai" "oci-ai" "8321";;
      2) project_menu "OCI IPv6 SOCKS5 Proxy" "$OCI_PROXY_REPO" "/opt/oci-ipv6-socks5-proxy" "oci-ipv6-socks5-proxy" "18080";;
      3) custom_project_install; pause;;
      0) break;; *) warn "无效选择"; sleep 1;;
    esac
  done
}

clone_or_update_repo() { local name="$1" repo="$2" dir="$3"; install_base_deps; mkdir -p "$(dirname "$dir")"; if [ -d "$dir/.git" ]; then warn "$name 已存在，执行 git pull"; git -C "$dir" pull --ff-only; else warn "克隆 $repo 到 $dir"; rm -rf "$dir"; git clone "$repo" "$dir"; fi; }
find_install_script() { local dir="$1"; for f in install.sh setup.sh deploy.sh run.sh main.sh start.sh; do [ -f "$dir/$f" ] && { echo "$dir/$f"; return 0; }; done; find "$dir" -maxdepth 2 -type f \( -name 'install*.sh' -o -name 'setup*.sh' -o -name 'deploy*.sh' \) 2>/dev/null | head -n1; }
run_project_install() { local name="$1" repo="$2" dir="$3"; clone_or_update_repo "$name" "$repo" "$dir" || return 1; local installer; installer="$(find_install_script "$dir")"; if [ -n "$installer" ]; then warn "找到安装脚本：$installer"; chmod +x "$installer"; (cd "$dir" && bash "$installer"); else warn "未发现标准安装脚本，已完成拉取：$dir"; fi; }
run_project_update() { local name="$1" repo="$2" dir="$3"; clone_or_update_repo "$name" "$repo" "$dir" || return 1; local installer; installer="$(find_install_script "$dir")"; [ -n "$installer" ] && confirm "是否重新执行安装/部署脚本？" && { chmod +x "$installer"; (cd "$dir" && bash "$installer"); }; }
run_project_uninstall() { local name="$1" dir="$2" service="$3"; warn "准备卸载 $name"; if [ -n "$service" ] && systemctl list-unit-files 2>/dev/null | grep -q "^${service}\.service"; then systemctl stop "$service" 2>/dev/null || true; systemctl disable "$service" 2>/dev/null || true; rm -f "/etc/systemd/system/${service}.service"; systemctl daemon-reload || true; fi; [ -d "$dir" ] && confirm "是否删除目录 $dir ?" && rm -rf "$dir"; log "处理完成"; }
open_firewall_port() { local port="$1"; [ -z "$port" ] && { err "端口为空"; return 1; }; if cmd_exists ufw; then ufw allow "$port/tcp" || true; fi; if cmd_exists firewall-cmd; then firewall-cmd --permanent --add-port="${port}/tcp" && firewall-cmd --reload || true; fi; if cmd_exists iptables; then iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -p tcp --dport "$port" -j ACCEPT || true; fi; log "已尝试放行端口 $port，云安全组也需要放行。"; }
install_caddy() { cmd_exists caddy && return 0; warn "安装 Caddy"; case "$(pm_detect)" in apt) pkg_install debian-keyring debian-archive-keyring apt-transport-https curl gpg; curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg; curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list; apt-get update; apt-get install -y caddy;; dnf|yum) pkg_install caddy;; *) pkg_install caddy;; esac; }
setup_domain_access() { local port="$1" domain; header; echo -e "${C_PURPLE}开启域名访问${C_RESET}"; small_line; echo "将安装/配置 Caddy，把域名反代到 127.0.0.1:${port}"; echo "请先把域名 A 记录解析到本机，并在云安全组放行 80/443。"; ask domain "请输入域名（留空取消）: "; [ -z "$domain" ] && return 0; install_caddy; mkdir -p /etc/caddy; [ -f /etc/caddy/Caddyfile ] && cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.bak.$(date +%Y%m%d%H%M%S)"; cat >> /etc/caddy/Caddyfile <<EOF_CADDY

${domain} {
    reverse_proxy 127.0.0.1:${port}
}
EOF_CADDY
systemctl enable --now caddy; systemctl reload caddy || systemctl restart caddy; open_firewall_port 80; open_firewall_port 443; log "https://${domain} 已反代到 127.0.0.1:${port}"; }
project_status() { local dir="$1" service="$2" port="$3"; header; echo -e "${C_PURPLE}项目状态${C_RESET}"; small_line; echo "目录: $dir"; [ -d "$dir/.git" ] && { echo "仓库: $(git -C "$dir" remote get-url origin 2>/dev/null || echo '-')"; echo "版本: $(git -C "$dir" rev-parse --short HEAD 2>/dev/null || echo '-')"; } || echo "仓库: 未拉取"; echo; [ -n "$service" ] && echo "服务状态: $(systemctl is-active "$service" 2>/dev/null || echo 未发现)"; [ -n "$port" ] && { echo; echo "端口监听:"; ss -lntp 2>/dev/null | grep ":$port " || echo "未发现 $port 监听"; }; }
project_menu() { local name="$1" repo="$2" dir="$3" service="$4" port="$5"; while true; do header; echo -e "${C_PURPLE}${name}${C_RESET}"; small_line; echo "仓库: $repo"; echo "目录: $dir"; echo "端口: $port"; small_line; echo "1. 安装"; echo "2. 卸载"; echo "3. 更新"; echo "4. 开启域名访问"; echo "5. 查看状态"; echo "6. 放行端口"; echo "0. 返回上级菜单"; line; if ! read -r -p "请选择: " n; then exit 0; fi; case "$n" in 1) run_project_install "$name" "$repo" "$dir"; pause;; 2) run_project_uninstall "$name" "$dir" "$service"; pause;; 3) run_project_update "$name" "$repo" "$dir"; pause;; 4) setup_domain_access "$port"; pause;; 5) project_status "$dir" "$service" "$port"; pause;; 6) open_firewall_port "$port"; pause;; 0) break;; *) warn "无效选择"; sleep 1;; esac; done; }
custom_project_install() { local repo dir name port service; ask repo "GitHub 仓库地址: "; [ -z "$repo" ] && return; ask dir "安装目录（默认 /opt/custom-app）: "; dir=${dir:-/opt/custom-app}; ask name "项目名称（默认 custom-app）: "; name=${name:-custom-app}; ask service "服务名（可留空）: "; ask port "端口（可留空）: "; project_menu "$name" "$repo" "$dir" "$service" "$port"; }

install_docker() { cmd_exists docker && { log "Docker 已安装：$(docker --version)"; return 0; }; warn "使用 Docker 官方脚本安装"; curl -fsSL https://get.docker.com -o /tmp/get-docker.sh; sh /tmp/get-docker.sh; systemctl enable --now docker; log "Docker 安装完成"; }
uninstall_docker() { confirm "确认卸载 Docker 软件包？不会删除 /var/lib/docker 数据。" || { warn "已取消"; return; }; systemctl stop docker 2>/dev/null || true; pkg_remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io docker-compose docker 2>/dev/null || true; }
docker_menu() { while true; do header; echo -e "${C_PURPLE}Docker 管理${C_RESET}"; small_line; echo "1. 安装 Docker / Compose"; echo "2. 启动 Docker"; echo "3. 停止 Docker"; echo "4. 重启 Docker"; echo "5. 查看 Docker 状态"; echo "6. 容器列表"; echo "7. 镜像列表"; echo "8. 清理无用镜像/容器/缓存"; echo "9. 卸载 Docker（保留数据）"; echo "0. 返回主菜单"; line; if ! read -r -p "请选择: " n; then exit 0; fi; case "$n" in 1) install_docker; pause;; 2) systemctl enable --now docker; pause;; 3) systemctl stop docker; pause;; 4) systemctl restart docker; pause;; 5) docker --version 2>/dev/null || true; docker compose version 2>/dev/null || true; systemctl status docker --no-pager -l 2>/dev/null || true; pause;; 6) docker ps -a; pause;; 7) docker images; pause;; 8) docker system prune -af; pause;; 9) uninstall_docker; pause;; 0) break;; *) warn "无效选择"; sleep 1;; esac; done; }

install_node_lts() { cmd_exists node && warn "当前 Node: $(node -v)"; case "$(pm_detect)" in apt) curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -; apt-get install -y nodejs;; dnf|yum) curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -; "$(pm_detect)" install -y nodejs;; *) pkg_install nodejs npm;; esac; }
cli_tools_menu() { while true; do header; echo -e "${C_PURPLE}基础工具${C_RESET}"; small_line; echo "1. 安装常用工具包"; echo "2. 安装/更新 uv"; echo "3. 安装 Node.js LTS"; echo "4. 安装 Python3/pip/venv"; echo "5. 安装 btop/htop/tmux/vim/nano"; echo "0. 返回主菜单"; line; if ! read -r -p "请选择: " n; then exit 0; fi; case "$n" in 1) pkg_install curl wget git unzip zip tar gzip jq htop tmux nano vim ca-certificates openssl socat net-tools iproute2 dnsutils lsof rsync cron sudo; pause;; 2) curl -LsSf https://astral.sh/uv/install.sh | sh; pause;; 3) install_node_lts; pause;; 4) pkg_install python3 python3-pip python3-venv python3-dev; pause;; 5) pkg_install btop htop tmux vim nano; pause;; 0) break;; *) warn "无效选择"; sleep 1;; esac; done; }

bbr_status() { sysctl net.ipv4.tcp_congestion_control 2>/dev/null; sysctl net.core.default_qdisc 2>/dev/null; lsmod | grep bbr || true; }
bbr_enable() { modprobe tcp_bbr 2>/dev/null || true; grep -q '^tcp_bbr$' /etc/modules 2>/dev/null || echo tcp_bbr >> /etc/modules; cat >/etc/sysctl.d/99-anan-bbr.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
sysctl --system; bbr_status; }
bbr_menu() { while true; do header; echo -e "${C_PURPLE}BBR 管理${C_RESET}"; small_line; echo "1. 查看 BBR 状态"; echo "2. 开启 BBR"; echo "3. Linux 网络参数优化（拉取 kejilion network-optimize）"; echo "0. 返回主菜单"; line; if ! read -r -p "请选择: " n; then exit 0; fi; case "$n" in 1) bbr_status; pause;; 2) bbr_enable; pause;; 3) curl -sS https://raw.githubusercontent.com/kejilion/sh/refs/heads/main/network-optimize.sh | bash; pause;; 0) break;; *) warn "无效选择"; sleep 1;; esac; done; }

warp_menu() { header; echo -e "${C_PURPLE}WARP 管理${C_RESET}"; small_line; echo "将拉取 fscarmen/warp 官方菜单脚本。"; confirm "是否继续？" && { pkg_install wget; wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh; }; }
test_scripts_menu() { while true; do header; echo -e "${C_PURPLE}测试脚本合集${C_RESET}"; small_line; echo "1. bench.sh 综合测试"; echo "2. yabs 性能测试"; echo "3. speedtest 网络测速"; echo "4. 三网回程测试"; echo "0. 返回主菜单"; line; if ! read -r -p "请选择: " n; then exit 0; fi; case "$n" in 1) curl -Lso- bench.sh | bash; pause;; 2) curl -sL yabs.sh | bash; pause;; 3) bash <(curl -sL https://raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh); pause;; 4) curl https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh|bash; pause;; 0) break;; *) warn "无效选择"; sleep 1;; esac; done; }
oracle_menu() {
  while true; do
    header
    echo -e "${C_PURPLE}甲骨文云脚本合集${C_RESET}"
    small_line
    echo "1. 安装/更新 OCI-AI"
    echo "2. 安装/更新 OCI IPv6 代理池"
    echo "3. 甲骨文实例网络/IP 信息"
    echo "4. OCI metadata VNIC/IPv6 信息"
    echo "0. 返回主菜单"
    line
    if ! read -r -p "请选择: " n; then exit 0; fi
    case "$n" in
      1) project_menu "OCI-AI" "$OCI_AI_REPO" "/opt/oci-ai" "oci-ai" "8321";;
      2) project_menu "OCI IPv6 SOCKS5 Proxy" "$OCI_PROXY_REPO" "/opt/oci-ipv6-socks5-proxy" "oci-ipv6-socks5-proxy" "18080";;
      3) ip addr; ip route; pause;;
      4) curl -fsS http://169.254.169.254/opc/v1/vnics/ || true; pause;;
      0) break;;
      *) warn "无效选择"; sleep 1;;
    esac
  done
}

set_shortcut() { local key target; ask key "请输入快捷按键（默认 a，输入0取消）: "; [ "$key" = "0" ] && return; key=${key:-a}; target="$INSTALL_DIR/anan-tools.sh"; mkdir -p "$INSTALL_DIR"; cp "$0" "$target"; chmod +x "$target"; ln -sf "$target" "/usr/local/bin/$key"; [ "$key" = "a" ] || ln -sf "$target" "$BIN_PATH"; ln -sf "$target" "$ALT_BIN_PATH"; log "已设置快捷命令：$key（默认 a 也可用），兼容命令：anan"; }
change_ssh_port() { local port; ask port "请输入新的 SSH 端口: "; [[ "$port" =~ ^[0-9]+$ ]] || { err "端口无效"; return; }; cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.bak.$(date +%Y%m%d%H%M%S)"; if grep -qE '^#?Port ' /etc/ssh/sshd_config; then sed -i "s/^#\?Port .*/Port $port/" /etc/ssh/sshd_config; else echo "Port $port" >> /etc/ssh/sshd_config; fi; open_firewall_port "$port"; systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || true; log "SSH 端口已改为 $port，请先新开窗口测试再断开当前连接。"; }
open_all_ports() { if cmd_exists ufw; then ufw disable || true; fi; if cmd_exists iptables; then iptables -P INPUT ACCEPT || true; iptables -P FORWARD ACCEPT || true; iptables -P OUTPUT ACCEPT || true; iptables -F || true; fi; log "已尝试开放本机端口；云安全组仍需单独设置。"; }
optimize_dns() { cp /etc/resolv.conf "/etc/resolv.conf.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true; cat >/etc/resolv.conf <<'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 223.5.5.5
EOF
log "DNS 已写入 1.1.1.1 / 8.8.8.8 / 223.5.5.5"; }
prefer_ip() { local mode="$1" file=/etc/gai.conf; cp "$file" "$file.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true; sed -i '/^precedence ::ffff:0:0\/96/d;/^#precedence ::ffff:0:0\/96/d' "$file" 2>/dev/null || true; [ "$mode" = ipv4 ] && echo 'precedence ::ffff:0:0/96  100' >> "$file"; log "已设置网络优先：$mode"; }
swap_set() { local mb; ask mb "请输入虚拟内存大小 MB（如 1024）: "; [[ "$mb" =~ ^[0-9]+$ ]] || return; swapoff /swapfile 2>/dev/null || true; rm -f /swapfile; fallocate -l "${mb}M" /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count="$mb"; chmod 600 /swapfile; mkswap /swapfile; swapon /swapfile; grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab; free -h; }
random_generator() { tr -dc 'A-Za-z0-9_@#%+=' </dev/urandom | head -c 24; echo; }
timezone_set() { local tz; ask tz "请输入时区（默认 Asia/Shanghai）: "; tz=${tz:-Asia/Shanghai}; timedatectl set-timezone "$tz"; timedatectl; }
hostname_set() { local h; ask h "请输入新主机名: "; [ -n "$h" ] && hostnamectl set-hostname "$h" && log "已修改主机名为 $h"; }
port_status() { ss -lntup 2>/dev/null || netstat -lntup 2>/dev/null || true; }
history_show() { for f in "$HOME/.bash_history" "$HOME/.zsh_history" "$HOME/.ash_history"; do [ -f "$f" ] && { nl -ba "$f"; return; }; done; warn "未找到历史记录文件"; }
one_click_tune() { header; echo "将执行：更新系统、清理、1G swap、开启 BBR、优化 DNS、安装基础工具。"; confirm "确认执行一条龙系统调优？" || return; pkg_upgrade; linux_clean; (echo 1024 | true); local old_read; swapoff /swapfile 2>/dev/null || true; fallocate -l 1024M /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=1024; chmod 600 /swapfile; mkswap /swapfile; swapon /swapfile; grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab; bbr_enable; optimize_dns; pkg_install docker.io wget sudo tar unzip socat btop nano vim curl git jq || true; log "一条龙调优完成"; }
advanced_usage() { echo "启动脚本: a"; echo "安装软件: a install nano wget"; echo "更新系统: a update"; echo "清理系统: a clean"; echo "Docker 面板: a docker"; echo "系统信息: a info"; echo "设置快捷键: a shortcut"; }

system_tools_menu() { while true; do header; echo -e "${C_PURPLE}系统工具${C_RESET}"; small_line
  echo -e "${C_CYAN}1.${C_RESET} 设置脚本启动快捷键                 ${C_CYAN}2.${C_RESET} 修改登录密码"
  echo -e "${C_CYAN}3.${C_RESET} 用户密码登录模式                   ${C_CYAN}4.${C_RESET} 安装Python指定版本"
  echo -e "${C_CYAN}5.${C_RESET} 开放所有端口                       ${C_CYAN}6.${C_RESET} 修改SSH连接端口"
  echo -e "${C_CYAN}7.${C_RESET} 优化DNS地址                        ${C_CYAN}8.${C_RESET} 一键重装系统 ★"
  echo -e "${C_CYAN}9.${C_RESET} 禁用ROOT账户创建新账户              ${C_CYAN}10.${C_RESET} 切换优先ipv4/ipv6"
  small_line
  echo -e "${C_CYAN}11.${C_RESET} 查看端口占用状态                   ${C_CYAN}12.${C_RESET} 修改虚拟内存大小"
  echo -e "${C_CYAN}13.${C_RESET} 用户管理                           ${C_CYAN}14.${C_RESET} 用户/密码生成器"
  echo -e "${C_CYAN}15.${C_RESET} 系统时区调整                       ${C_CYAN}16.${C_RESET} 设置BBR加速"
  echo -e "${C_CYAN}17.${C_RESET} 防火墙高级管理器                   ${C_CYAN}18.${C_RESET} 修改主机名"
  echo -e "${C_CYAN}19.${C_RESET} 切换系统更新源                     ${C_CYAN}20.${C_RESET} 定时任务管理"
  small_line
  echo -e "${C_CYAN}21.${C_RESET} 本机host解析                       ${C_CYAN}22.${C_RESET} SSH防御程序"
  echo -e "${C_CYAN}23.${C_RESET} 限流自动关机                       ${C_CYAN}24.${C_RESET} 用户密钥登录模式"
  echo -e "${C_CYAN}25.${C_RESET} TG-bot系统监控预警                 ${C_CYAN}26.${C_RESET} 修复OpenSSH高危漏洞"
  echo -e "${C_CYAN}27.${C_RESET} 红帽系Linux内核升级                ${C_CYAN}28.${C_RESET} Linux系统内核参数优化 ★"
  echo -e "${C_CYAN}29.${C_RESET} 病毒扫描工具 ★                     ${C_CYAN}30.${C_RESET} 文件管理器"
  small_line
  echo -e "${C_CYAN}31.${C_RESET} 切换系统语言                       ${C_CYAN}32.${C_RESET} 命令行美化工具 ★"
  echo -e "${C_CYAN}33.${C_RESET} 设置系统回收站                     ${C_CYAN}34.${C_RESET} 系统备份与恢复"
  echo -e "${C_CYAN}35.${C_RESET} ssh远程连接工具                    ${C_CYAN}36.${C_RESET} 硬盘分区管理工具"
  echo -e "${C_CYAN}37.${C_RESET} 命令行历史记录                     ${C_CYAN}38.${C_RESET} rsync远程同步工具"
  echo -e "${C_CYAN}39.${C_RESET} 命令收藏夹 ★                       ${C_CYAN}40.${C_RESET} 网卡管理工具"
  echo -e "${C_CYAN}41.${C_RESET} 系统日志管理工具 ★                 ${C_CYAN}42.${C_RESET} 系统变量管理工具"
  small_line
  echo -e "${C_CYAN}66.${C_RESET} 一条龙系统调优 ★                  ${C_CYAN}99.${C_RESET} 重启服务器"
  echo -e "${C_CYAN}101.${C_RESET} a命令高级用法                    ${C_CYAN}102.${C_RESET} 卸载 anan 脚本"
  echo "0. 返回主菜单"; line
  if ! read -r -p "请输入你的选择: " n; then exit 0; fi
  case "$n" in
    1) set_shortcut; pause;; 2) passwd; pause;; 3) warn "请使用选项24或手动编辑 /etc/ssh/sshd_config"; pause;; 4) pkg_install python3 python3-pip python3-venv; pause;;
    5) open_all_ports; pause;; 6) change_ssh_port; pause;; 7) optimize_dns; pause;; 8) echo "重装系统风险极高，建议单独确认发行版后再执行。"; pause;;
    9) adduser anan-admin && usermod -aG sudo anan-admin; passwd -l root; pause;; 10) echo "1.ipv4优先 2.ipv6优先"; read -r x; [ "$x" = 1 ] && prefer_ip ipv4 || prefer_ip ipv6; pause;;
    11) port_status; pause;; 12) swap_set; pause;; 13) cut -d: -f1 /etc/passwd; pause;; 14) random_generator; pause;; 15) timezone_set; pause;; 16) bbr_menu;;
    17) if cmd_exists ufw; then ufw status verbose; else pkg_install ufw; ufw status verbose; fi; pause;; 18) hostname_set; pause;; 19) warn "换源因系统差异大，暂保留为手动项。"; pause;; 20) crontab -e; pause;;
    21) ${EDITOR:-nano} /etc/hosts; pause;; 22) pkg_install fail2ban; systemctl enable --now fail2ban; fail2ban-client status || true; pause;; 23) warn "限流自动关机需要你提供阈值策略，暂不自动执行。"; pause;; 24) ${EDITOR:-nano} /etc/ssh/sshd_config; systemctl restart sshd 2>/dev/null || systemctl restart ssh || true; pause;;
    25) warn "TG bot 监控需要 Bot Token 和 chat_id，后续可单独接入。"; pause;; 26) warn "OpenSSH 修复请确认系统版本后单独执行，避免断连。"; pause;; 27) warn "仅红帽系适用，请确认后手动执行 elrepo。"; pause;; 28) curl -sS https://raw.githubusercontent.com/kejilion/sh/refs/heads/main/network-optimize.sh | bash; pause;;
    29) pkg_install clamav clamav-daemon; freshclam || true; clamscan --version; pause;; 30) ${EDITOR:-nano} .; pause;; 31) dpkg-reconfigure locales 2>/dev/null || warn "当前系统不支持 dpkg-reconfigure locales"; pause;; 32) warn "可安装 zsh/oh-my-zsh 或 starship，暂不强制修改 shell。"; pause;;
    33) mkdir -p ~/.trash; echo 'alias rm="mv -t ~/.trash"' >> ~/.bashrc; log "已添加回收站 alias，重新登录生效"; pause;; 34) tar -czf "/root/anan-backup-$(date +%F).tar.gz" /etc /root 2>/dev/null || true; pause;; 35) ask h "SSH 目标 user@host: "; [ -n "$h" ] && ssh "$h"; pause;; 36) lsblk -f; pause;;
    37) history_show; pause;; 38) pkg_install rsync; rsync --version | head; pause;; 39) ${EDITOR:-nano} ~/.anan_fav; pause;; 40) ip addr; ip route; pause;; 41) journalctl -xe --no-pager | tail -200; pause;; 42) env | sort; pause;;
    66) one_click_tune; pause;; 99) confirm "确认重启服务器？" && reboot;; 101) advanced_usage; pause;; 102) uninstall_self; pause;; 0) break;; *) warn "无效选择"; sleep 1;;
  esac
done; }

install_self() { need_root; install_base_deps; mkdir -p "$INSTALL_DIR"; cp "$0" "$INSTALL_DIR/anan-tools.sh"; chmod +x "$INSTALL_DIR/anan-tools.sh"; ln -sf "$INSTALL_DIR/anan-tools.sh" "$BIN_PATH"; ln -sf "$INSTALL_DIR/anan-tools.sh" "$ALT_BIN_PATH"; log "已安装快捷命令：a（兼容 anan）"; }
uninstall_self() { need_root; rm -f "$BIN_PATH" "$ALT_BIN_PATH"; confirm "是否删除 $INSTALL_DIR ?" && rm -rf "$INSTALL_DIR"; log "工具箱卸载完成"; }
self_update() { need_root; install_base_deps; if [ -d "$INSTALL_DIR/.git" ]; then git -C "$INSTALL_DIR" pull --ff-only; else mkdir -p "$INSTALL_DIR"; curl -fsSL "$REPO_RAW" -o "$INSTALL_DIR/anan-tools.sh"; fi; chmod +x "$INSTALL_DIR/anan-tools.sh"; ln -sf "$INSTALL_DIR/anan-tools.sh" "$BIN_PATH"; ln -sf "$INSTALL_DIR/anan-tools.sh" "$ALT_BIN_PATH"; log "脚本更新完成"; }

main_menu() { need_root; while true; do header
  echo -e "${C_CYAN}1.${C_RESET}   系统信息查询"
  echo -e "${C_CYAN}2.${C_RESET}   系统更新"
  echo -e "${C_CYAN}3.${C_RESET}   系统清理"
  echo -e "${C_CYAN}4.${C_RESET}   基础工具"
  echo -e "${C_CYAN}5.${C_RESET}   BBR管理"
  echo -e "${C_CYAN}6.${C_RESET}   Docker管理"
  echo -e "${C_CYAN}7.${C_RESET}   WARP管理"
  echo -e "${C_CYAN}8.${C_RESET}   测试脚本合集"
  echo -e "${C_CYAN}9.${C_RESET}   甲骨文云脚本合集"
  echo -e "${C_YELLOW}10.${C_RESET}  我的软件仓库"
  echo -e "${C_CYAN}11.${C_RESET}  应用市场（预留）"
  echo -e "${C_CYAN}12.${C_RESET}  后台工作区（预留）"
  echo -e "${C_CYAN}13.${C_RESET}  系统工具"
  small_line
  echo -e "${C_CYAN}00.${C_RESET}  脚本更新"
  echo -e "${C_CYAN}0.${C_RESET}   退出脚本"
  line
  if ! read -r -p "请输入你的选择: " choice; then exit 0; fi
  case "$choice" in
    1) system_info; pause;; 2) system_update_menu;; 3) linux_clean; pause;; 4) cli_tools_menu;; 5) bbr_menu;; 6) docker_menu;; 7) warp_menu; pause;; 8) test_scripts_menu;; 9) oracle_menu;; 10) software_repo_menu;; 11) warn "应用市场预留：以后可接你的软件列表仓库。"; pause;; 12) warn "后台工作区预留。"; pause;; 13) system_tools_menu;; 00) self_update; pause;; 0) echo "拜拜～"; exit 0;; *) warn "无效输入"; sleep 1;;
  esac
done; }

case "${1:-}" in
  --version|-v) echo "$VERSION";;
  --install-self|install-self|shortcut) install_self;;
  --uninstall-self|uninstall-self) uninstall_self;;
  --system-info|info) system_info;;
  update|更新) pkg_upgrade;;
  clean|清理) linux_clean;;
  install|add|安装) shift; pkg_install "$@";;
  remove|del|uninstall|卸载) shift; pkg_remove "$@";;
  docker) docker_menu;;
  tools) cli_tools_menu;;
  bbr) bbr_menu;;
  software|soft) software_repo_menu;;
  system-tools|settings) system_tools_menu;;
  --help|-h) echo "用法: $0 [--install-self|--uninstall-self|info|update|clean|install 包名|docker|tools|bbr|software|system-tools|--version]";;
  *) main_menu;;
esac
