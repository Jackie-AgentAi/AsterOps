# OpenClaw 家庭服务器部署完整教程（Ubuntu 24.04）

## 架构概览

```
[家里服务器 Ubuntu 24.04]
  ├── openclaw gateway（守护进程，端口 18789）
  ├── UFW 防火墙（仅放行 Tailscale 网卡流量）
  ├── SSH（仅 Tailscale 内网可达，密钥登录）
  └── Tailscale（加密隧道，无需公网 IP）
         │
         ▼ 端对端加密，账号认证
  [办公室 / 手机]
  浏览器 / 飞书 / QQ / SSH 客户端
```

安全原则：**服务不暴露公网，所有外部访问经 Tailscale 加密隧道进入。**

---

## 第一步：系统基础依赖

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential openssl ca-certificates jq fail2ban ufw
```

---

## 第二步：安装 Node.js 24

```bash
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs

node -v    # 应为 v24.x.x
npm -v
```

---

## 第三步：安装 pnpm 并配置全局目录

```bash
sudo npm install -g pnpm

# 初始化全局目录并写入 PATH
pnpm setup
source ~/.bashrc
```

---

## 第四步：安装 OpenClaw

使用官方安装脚本（推荐，自动处理依赖和版本）：

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
source ~/.bashrc
```

或手动用 pnpm 安装：

```bash
pnpm add -g openclaw@latest
```

验证安装：

```bash
which openclaw
openclaw --version
```

---

## 第五步：初始化向导（自动安装守护进程）

```bash
openclaw onboard --install-daemon
```

向导会引导你完成以下配置，并自动注册 systemd 服务实现开机自启和崩溃重启：

- Gateway 端口（默认 18789）
- API Key 配置（见下一步）
- 守护进程安装

---

## 第六步：配置 AI 模型

按需选择一个或多个模型提供商，至少配置一个：

### OpenRouter（推荐，聚合多家模型，一个 Key 通吃）

```bash
openclaw config set models.openrouter.apiKey "sk-or-你的key"
openclaw config set models.openrouter.defaultModel "anthropic/claude-sonnet-4-6"
```

常用 OpenRouter 模型名称：

```
anthropic/claude-sonnet-4-6
anthropic/claude-opus-4-6
openai/gpt-4o
google/gemini-2.0-flash
```

### MiniMax

```bash
openclaw config set models.minimax.apiKey "你的MiniMax_apiKey"
openclaw config set models.minimax.groupId "你的MiniMax_groupId"
openclaw config set models.minimax.defaultModel "abab6.5s-chat"
```

### GLM-4.7（智谱 AI）

```bash
openclaw config set models.zhipu.apiKey "你的智谱APIKey"
openclaw config set models.zhipu.defaultModel "glm-4v-flash"
```

常用 GLM 模型名称：

```
glm-4-flash      # 免费，速度快
glm-4v-flash     # 支持视觉
glm-4-air        # 性价比高
```

### Anthropic Claude（直连）

```bash
openclaw config set models.anthropic.apiKey "sk-ant-你的key"
openclaw config set models.anthropic.defaultModel "claude-sonnet-4-6"
```

配置完成后重启 Gateway 生效：

```bash
openclaw gateway restart
```

---

## 第七步：配置常用 Skills

```bash
# 查看可用 skills
openclaw skills list

# 启用网页搜索
openclaw skills enable web-search

# 启用代码执行
openclaw skills enable code-runner

# 启用文件读写
openclaw skills enable file-manager

# 确认已启用的 skills
openclaw config get skills
```

---

## 第八步：配置飞书接入

在飞书开放平台创建机器人应用后，执行以下配置：

```bash
cd ~

openclaw config set channels.feishu.enabled true
openclaw config set channels.feishu.connectionMode websocket
openclaw config set channels.feishu.dmPolicy pairing
openclaw config set channels.feishu.groupPolicy allowlist
openclaw config set channels.feishu.requireMention true

# 填写允许触发的飞书机器人名称
openclaw config set channels.feishu.groupAllowFrom '["clawdbot", "clawdbot2"]'

openclaw gateway restart
```

> 飞书机器人需在开放平台配置**事件订阅 Webhook** 地址为：`http://100.x.x.x:18789/channels/feishu`（替换为你的 Tailscale IP）。

---

## 第九步：配置 QQ 接入

```bash
# 安装 QQBot 插件
openclaw plugins install @tencent-connect/openclaw-qqbot@latest

# 添加 QQBot 渠道（替换为你的实际 token）
openclaw channels add --channel qqbot --token "你的QQBot_token"

openclaw gateway restart
```

> QQ 机器人 token 在 [QQ 开放平台](https://q.qq.com/) 创建机器人应用后获取。

---

## 第十步：远程访问与 SSH（Tailscale）

Tailscale 免费、无需公网 IP、无需路由器端口转发、端对端加密，是家庭服务器远程访问的首选方案。

### 10.1 安装 Tailscale 并开启 SSH

```bash
curl -fsSL https://tailscale.com/install.sh | sh

# 启动并开启 Tailscale 内置 SSH（推荐）
sudo tailscale up --ssh

# 查看分配的 Tailscale IP
tailscale ip -4
# 例如：100.x.x.x
```

> `--ssh` 参数让 Tailscale 托管 SSH 认证，无需管理密钥，支持 ACL 控制访问权限。

### 10.2 将 Gateway 绑定到所有网卡

```bash
openclaw config set gateway.bind 0.0.0.0
openclaw gateway restart
```

### 10.3 客户端（办公室 / 笔记本）连接

安装对应平台的 Tailscale 客户端，同账号登录后：

```bash
# SSH 进入服务器
ssh 用户名@100.x.x.x

# 浏览器访问 OpenClaw 控制面板
# http://100.x.x.x:18789/
```

查看 Gateway Token：

```bash
openclaw config get gateway.auth.token
```

在控制面板 Settings 中填入 Token 完成认证。

### 10.4 配置 SSH 密钥登录（可选，使用系统 sshd 时）

```bash
# 在本机生成密钥（已有可跳过）
ssh-keygen -t ed25519 -C "my-office-key"

# 将公钥推送到服务器
ssh-copy-id 用户名@100.x.x.x
```

在本机 `~/.ssh/config` 中添加别名，之后 `ssh home-server` 一键连入：

```
Host home-server
    HostName     100.x.x.x
    User         你的用户名
    IdentityFile ~/.ssh/id_ed25519
```

### 10.5 SSH 本地端口转发（无需安装 Tailscale 客户端时的备用方案）

当客户端无法安装 Tailscale（如临时借用的电脑），可通过 SSH 隧道将服务器的 18789 端口映射到本地：

```bash
# 建立隧道（后台持续运行，不打开 shell）
ssh -N -L 18789:127.0.0.1:18789 用户名@服务器公网IP或Tailscale_IP

# 需要后台运行时加 -f
ssh -fN -L 18789:127.0.0.1:18789 用户名@服务器公网IP或Tailscale_IP
```

隧道建立后，在**本机**浏览器打开：

```
http://127.0.0.1:18789/
```

即可访问远程服务器上的 OpenClaw 控制面板，流量全程走 SSH 加密传输。

**关闭隧道：**

```bash
# 查找隧道进程
ps aux | grep "ssh -"

# 结束进程
kill <PID>
```

**在 `~/.ssh/config` 中配置隧道别名（推荐）：**

```
Host home-tunnel
    HostName     服务器IP
    User         你的用户名
    IdentityFile ~/.ssh/id_ed25519
    LocalForward 18789 127.0.0.1:18789
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

之后一条命令建立隧道：

```bash
ssh -fN home-tunnel
```

> **注意：** SSH 隧道方案要求服务器 SSH 端口（22）可从外部访问。若服务器仅在 Tailscale 内网，则先连接 Tailscale 再建隧道，或直接用 Tailscale IP 访问控制面板（推荐）。

### 10.6 常用远程调试命令

SSH 进入后：

```bash
# 查看 OpenClaw 运行状态
openclaw gateway status

# 实时查看日志
journalctl -u openclaw -f

# 升级 OpenClaw
pnpm add -g openclaw@latest && openclaw gateway restart

# 安装系统软件包
sudo apt install -y <包名>

# 安装 npm 全局工具
pnpm add -g <包名>

# 查看端口占用
ss -tunlp | grep 18789

# 查看资源占用
htop
```

---

## 第十一步：安全加固

### 11.1 SSH 加固

编辑 SSH 配置文件：

```bash
sudo nano /etc/ssh/sshd_config
```

修改或确认以下项（找到对应行取消注释并修改，没有则追加）：

```
# 禁止 root 直接登录
PermitRootLogin no

# 禁止密码登录，只允许密钥
PasswordAuthentication no
PubkeyAuthentication yes

# 禁止空密码
PermitEmptyPasswords no

# 关闭不需要的认证方式
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no

# 空闲超时自动断开（秒）
ClientAliveInterval 300
ClientAliveCountMax 2

# 限制最大同时未认证连接数
MaxStartups 3:50:10
```

应用配置：

```bash
sudo sshd -t          # 先测试配置无误
sudo systemctl restart ssh
```

### 11.2 UFW 防火墙（端口安全）

基本原则：**默认拒绝所有入站，仅放行必要端口，且只对 Tailscale 网卡开放服务端口。**

```bash
# 重置并设置默认策略
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 放行 SSH（仅 Tailscale 网卡 tailscale0，避免暴露到公网）
sudo ufw allow in on tailscale0 to any port 22 proto tcp

# 放行 OpenClaw Gateway（仅 Tailscale 内网访问）
sudo ufw allow in on tailscale0 to any port 18789 proto tcp

# 放行 Tailscale 自身的 UDP 端口（与外部建立隧道用）
sudo ufw allow 41641/udp

# 启用防火墙
sudo ufw enable
sudo ufw status verbose
```

> 这样 SSH 和 OpenClaw 端口对公网完全不可见，只有 Tailscale 内网设备才能访问。

### 11.3 fail2ban（暴力破解防护）

即使 SSH 只在 Tailscale 内网，fail2ban 也能防止内网其他设备暴力尝试：

```bash
sudo systemctl enable fail2ban --now
```

创建本地配置（避免升级覆盖）：

```bash
sudo nano /etc/fail2ban/jail.local
```

写入：

```ini
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
backend = systemd
```

```bash
sudo systemctl restart fail2ban

# 查看封禁状态
sudo fail2ban-client status sshd
```

### 11.4 OpenClaw Gateway Web 安全

**Token 强度：** Gateway Token 由 openclaw 自动生成，足够强，不要手动替换为简单字符串。

```bash
# 定期轮换 Token
openclaw doctor --generate-gateway-token

# 查看当前 Token
openclaw config get gateway.auth.token
```

**设备管理：** 仅审批你认识的设备，定期检查设备列表：

```bash
# 查看已接入设备
openclaw devices list

# 撤销可疑设备
openclaw devices revoke <device-id>
```

**配置文件权限：** 确保配置文件只有当前用户可读：

```bash
chmod 600 ~/.openclaw/openclaw.json
```

### 11.5 系统自动安全更新

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

确认配置文件中安全更新已启用：

```bash
cat /etc/apt/apt.conf.d/20auto-upgrades
```

应包含：

```
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

### 11.6 安全检查清单

定期执行以下检查：

```bash
# 查看当前登录用户
who

# 查看最近登录记录
last -n 20

# 查看 SSH 失败登录
sudo journalctl -u ssh --since "24 hours ago" | grep "Failed"

# 查看监听端口（确认没有意外开放的端口）
ss -tunlp

# 查看 UFW 状态
sudo ufw status verbose

# 查看 fail2ban 封禁列表
sudo fail2ban-client status sshd

# 查看 Tailscale 已连接设备
tailscale status
```

---

## 升级 OpenClaw

```bash
pnpm add -g openclaw@latest
openclaw gateway restart
openclaw --version
```

---

## 日常运维命令

```bash
# 查看 Gateway 状态
openclaw gateway status

# 重启 Gateway
openclaw gateway restart

# 停止 Gateway
openclaw gateway stop

# 前台运行（调试用）
openclaw gateway --port 18789 --verbose

# 诊断并修复常见问题
openclaw doctor --fix

# 查看设备列表
openclaw devices list

# 审批新设备
openclaw devices approve <device-id>

# 查看完整配置
openclaw config

# 刷新 Gateway Token
openclaw doctor --generate-gateway-token
```

---

## 常见问题

| 问题 | 解决方法 |
| ---- | ------- |
| 权限报错 | 用 pnpm 安装无需 sudo，检查全局目录权限 |
| 服务启动后立即退出 | `openclaw doctor --fix` 或 `journalctl -u openclaw -f` |
| 远程无法访问 18789 | 确认 UFW 已放行 tailscale0 网卡的 18789 端口 |
| 远程显示 unauthorized | `openclaw config get gateway.auth.token` 重新获取 token |
| SSH 连接被拒绝 | 确认 `tailscale status` 显示设备在线，检查 UFW 规则 |
| 飞书消息无响应 | 确认 `requireMention true` 且 @ 了机器人 |
| QQ 插件加载失败 | `openclaw plugins list` 确认插件已安装，重启 Gateway |
| Node.js 版本不对 | 重新执行第二步，确认 `node -v` 为 v24+ |

---

## 附录：网络代理配置（无图形界面环境）

若服务器无法直连 GitHub、npm 等境外资源，可使用 Clash 核心在命令行下配置代理。适用于 `init 3`（纯命令行）或无桌面的服务器环境。

> **说明：** Clash Verge 等 GUI 客户端依赖图形界面，服务器环境只能使用纯 Clash 核心。

### A.1 安装 Clash 核心

```bash
# 下载核心（替换为最新版本号）
wget https://github.com/Dreamacro/clash/releases/download/v1.18.0/clash-linux-amd64-v1.18.0.gz
gzip -d clash-linux-amd64-v1.18.0.gz
chmod +x clash-linux-amd64-v1.18.0
sudo mv clash-linux-amd64-v1.18.0 /usr/local/bin/clash
```

### A.2 配置文件

```bash
mkdir -p ~/.config/clash

# 下载订阅配置（替换为你的订阅链接）
wget -O ~/.config/clash/config.yaml "你的订阅链接"

# 下载 IP 数据库
wget -O ~/.config/clash/Country.mmdb \
  https://github.com/Dreamacro/maxmind-geoip/releases/download/20250312/Country.mmdb
```

### A.3 启动与设置终端代理

```bash
# 后台运行 Clash
clash -d ~/.config/clash &

# 设置终端代理（仅当前 Shell 会话有效）
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export all_proxy=socks5://127.0.0.1:7890

# 验证是否走代理
curl ifconfig.me
```

### A.4 配置开机自启（systemd）

```bash
sudo tee /etc/systemd/system/clash.service <<EOF
[Unit]
Description=Clash Daemon
After=network.target

[Service]
ExecStart=/usr/local/bin/clash -d /home/你的用户名/.config/clash
Restart=on-failure
User=你的用户名

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now clash
```

### A.5 常见问题

| 问题 | 解决方法 |
| ---- | ------- |
| 无图形界面无法启动 Clash Verge | 改用纯 Clash 核心，参考本附录 |
| 依赖缺失 | `sudo apt --fix-broken install` |
| TUN 模式异常 | 关闭 TUN 模式后重试，或检查内核模块是否加载 |
