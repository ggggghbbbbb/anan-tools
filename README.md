# 安安服务器工具箱

仿照 kejilion 风格做的服务器菜单脚本：一个入口，集中管理系统信息、系统更新、常用软件、常用 GitHub 项目安装/卸载/更新/域名访问。

## 一键运行

```bash
curl -sS -O https://raw.githubusercontent.com/ggggghbbbbb/anan-tools/main/anan-tools.sh && chmod +x anan-tools.sh && ./anan-tools.sh
```

也可以下载后安装快捷命令：

```bash
./anan-tools.sh --install-self
anan
```

## 当前菜单

- 系统信息
  - OS / 内核 / 架构 / CPU / 内存 / 磁盘 / IPv4 / IPv6
- 系统更新
  - 更新软件源
  - 更新系统软件包
  - 安装基础依赖
- 常用软件
  - OCI-AI 脚本
    - 安装
    - 卸载
    - 更新
    - 开启域名访问（Caddy 反代）
    - 查看状态
    - 放行端口
  - OCI IPv6 SOCKS5 Proxy 代理池
    - 安装
    - 卸载
    - 更新
    - 开启域名访问（Caddy 反代）
    - 查看状态
    - 放行端口
  - Docker / Docker Compose
  - 常用命令行工具

## 默认项目仓库

- OCI-AI: <https://github.com/ggggghbbbbb/OCI-AI>
- OCI IPv6 SOCKS5 Proxy: <https://github.com/ggggghbbbbb/OCI-IPv6-SOCKS5-PROXY>

如需临时覆盖仓库：

```bash
OCI_AI_REPO=https://github.com/你的仓库/OCI-AI.git ./anan-tools.sh
OCI_PROXY_REPO=https://github.com/你的仓库/OCI-IPv6-SOCKS5-PROXY.git ./anan-tools.sh
```

## 支持系统

脚本会自动识别常见包管理器：

- Debian / Ubuntu: `apt`
- CentOS / Rocky / Alma / Fedora: `yum` / `dnf`
- Alpine: `apk`
- Arch: `pacman`

## 注意

- 请使用 root 运行。
- “开启域名访问”会安装/配置 Caddy，并追加写入 `/etc/caddy/Caddyfile`。
- 云服务器还需要在云厂商安全组放行对应端口、80、443。
- 项目安装时会优先查找 `install.sh`、`setup.sh`、`deploy.sh` 等脚本并执行；如果项目仓库没有标准安装脚本，则只完成拉取并提示手动查看 README。
