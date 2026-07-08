# 安安 anan 脚本工具箱

一个仿 kejilion 风格的菜单式服务器工具箱：主入口负责系统维护、Docker、基础工具、BBR、WARP、测试脚本、甲骨文云脚本、系统工具；你自己的项目统一放到“我的软件仓库”。

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
- 11 应用市场（预留）
- 12 后台工作区（预留）
- 13 系统工具
- 00 脚本更新

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

## 兼容命令

```bash
a info
a update
a clean
a install nano wget
a docker
a tools
a bbr
a software
a system-tools
```

## 注意

- 请使用 root 运行。
- “开启域名访问”会安装/配置 Caddy，并追加写入 `/etc/caddy/Caddyfile`。
- 云服务器还需要在云厂商安全组放行对应端口、80、443。
- 涉及 SSH、重启、开放端口、DNS、swap 等系统工具操作前请确认风险。
