# 安安 anan 脚本工具箱

一个仿 kejilion 风格的菜单式服务器工具箱：主入口负责系统维护、Docker、基础工具、BBR、WARP、测试脚本、甲骨文云脚本、应用市场、后台工作区、系统工具；你自己的项目统一放到“我的软件仓库”。

## 一键运行

```bash
curl -sS -O https://raw.githubusercontent.com/ggggghbbbbb/anan-tools/main/anan-tools.sh && chmod +x anan-tools.sh && ./anan-tools.sh
```

## 安装快捷命令

默认快捷命令是 `a`，兼容 `anan`：

```bash
./anan-tools.sh --install-self
# 以后直接输入：
a
```

## 主菜单

- 1 系统信息查询
- 2 系统更新
- 3 系统清理
- 4 基础工具
- 5 BBR管理
- 6 Docker管理
- 7 WARP管理
- 8 测试脚本合集
- 9 甲骨文云脚本合集
- 10 我的软件仓库
- 11 应用市场
- 12 后台工作区
- 13 系统工具
- 00 脚本更新

## 已安装检测和绿色标记

脚本现在会在安装前先检测本机是否已经安装过：

- 系统包：检测包管理器记录和命令是否存在
- Docker：检测 `docker` 命令
- 我的软件仓库：检测安装目录、systemd 服务、默认端口
- 应用市场：检测命令、目录、systemd 服务、Docker 容器或端口

检测到已安装的软件会在菜单里显示为绿色，并且再次执行安装时会提示“已安装”并跳过，避免重复安装。

## 我的软件仓库

这里用于以后单独存放你的项目，目前默认包含：

- OCI-AI：<https://github.com/ggggghbbbbb/OCI-AI>
- OCI IPv6 SOCKS5 Proxy：<https://github.com/ggggghbbbbb/OCI-IPv6-SOCKS5-PROXY>
- 自定义 GitHub 项目拉取/安装

每个项目都有：

- 安装
- 卸载
- 更新
- 开启域名访问
- 查看状态
- 放行端口

## 应用市场

已加入 kejilion 风格应用市场菜单，已补全参考脚本里的 1-115 个应用条目，包含宝塔、1Panel、Nginx Proxy Manager、哪吒、qBittorrent、Portainer、Open WebUI、Gitea、FileBrowser、Firefox、OpenClaw、Hermes 等。

当前部分应用已接入自动安装，未接入的条目会先做已安装检测并提示后续可补充安装方式。

## 后台工作区

基于 `tmux` 实现：

- 1-10 号工作区
- SSH 常驻模式
- 创建/进入自定义工作区
- 注入命令到后台工作区
- 删除指定工作区

进入工作区后按 `Ctrl+b`，再按 `d`，可以退出但任务不中断。

## 兼容命令

```bash
a info
a update
a clean
a install nano wget
a docker
a tools
a bbr
a app
a work
a software
a system-tools
```

## 注意

- 请使用 root 运行。
- “开启域名访问”会安装/配置 Caddy，并追加写入 `/etc/caddy/Caddyfile`。
- 云服务器还需要在云厂商安全组放行对应端口、80、443。
- 涉及 SSH、重启、开放端口、DNS、swap 等系统工具操作前请确认风险。
