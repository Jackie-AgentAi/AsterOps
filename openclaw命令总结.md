openclaw 命令总结（2026-03-09）

## 一、系统与 Node / npm 环境准备

```bash
sudo apt update && sudo apt upgrade -y

# 安装 Node 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 如需升级到 Node 24
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs

node -v

# 安装 / 升级 npm
apt-get install npm -y
npm install -g npm@11.11.0
npm -v

# （可选）安装 nvm 管理 Node 版本
apt install nvm
nvm install 22
```

## 二、pnpm 安装与全局目录配置

```bash
# 通过 npm 安装 pnpm
sudo npm install -g pnpm

# 查看 pnpm 全局 bin 目录
pnpm config get global-bin-dir

# 自动初始化 pnpm 全局目录（写入 .bashrc 等）
pnpm setup

# 让配置立即生效（或重启终端）
source ~/.bashrc
source ~/.bashrc
```

## 三、openclaw CLI 安装与卸载

```bash
# 验证当前是否已经存在 openclaw
which openclaw

# 通过 pnpm 安装（推荐）
pnpm add -g openclaw@latest

# 如之前装过旧包，先卸载
pnpm remove -g @openclaw/cli openclaw

# 再重新安装
pnpm add -g openclaw@latest

# 如改用 npm 全局安装
npm install -g openclaw@latest
npm uninstall -g openclaw@latest

# 官方安装脚本（封装了以上流程，可多次执行）
curl -fsSL https://openclaw.ai/install.sh | bash
```

## 四、openclaw 初始向导与守护进程

```bash
# 运行 Onboarding 向导并安装守护进程
openclaw onboard --install-daemon
```

## 五、Feishu 渠道配置（在当前用户家目录环境下）

```bash
cd ~

openclaw config set channels.feishu.enabled true
openclaw config set channels.feishu.connectionMode websocket
openclaw config set channels.feishu.dmPolicy pairing
openclaw config set channels.feishu.groupPolicy allowlist
openclaw config set channels.feishu.requireMention true
openclaw config set channels.feishu.groupAllowFrom '["clawdbot", "clawdbot2"]'
```

## 六、Gateway 运行与调试

```bash
# 前台运行 Gateway（调试用）
openclaw gateway --port 18789 --verbose

# 重启 Gateway（systemd/守护进程）
openclaw gateway restart

# 停止 Gateway
openclaw gateway stop

# 查看 Gateway 状态
openclaw gateway status

# 诊断并修复常见问题
openclaw doctor --fix
```

## 七、Gateway 访问配置与令牌

```bash
# 生成/刷新 Gateway 访问令牌
openclaw doctor --generate-gateway-token

# 读取当前 Gateway token
openclaw config get gateway.auth.token
grep token /home/jackie/.openclaw/openclaw.json

# 在 shell 中导出并拼出访问地址
NEW_TOKEN=$(openclaw config get gateway.auth.token)
echo "新的有效访问地址：http://127.0.0.1:18789/#token=$NEW_TOKEN"
```

## 八、Gateway 监听地址与远程访问

```bash
# 将 Gateway 绑定到 0.0.0.0 以便远程访问
openclaw config set gateway.bind 0.0.0.0
openclaw gateway restart

# 如需手工编辑配置文件
sudo vi /home/jackie/.openclaw/openclaw.json
openclaw gateway restart
```

## 九、网络连通性与端口检查

```bash
# 检查 18789 端口监听
netstat -tunpl | grep 18

# 从远程 Windows 端测试 WebSocket/HTTP 端口
telnet.exe 127.0.0.1 18789
```

## 十、设备配对与配置查看

```bash
# 查看当前设备列表
openclaw devices list

# 审批新设备（示例 ID）
openclaw devices approve 7367eab6-c15b-4ea7-b771-ad51032f1c95

# 查看当前配置（多次执行用来确认修改是否生效）
openclaw config

# 直接编辑配置文件
vim ~/.openclaw/openclaw.json
sudo vi /home/jackie/.openclaw/openclaw.json
```

## 十一、插件与渠道配置（示例：QQ 机器人）

```bash
# 安装 QQBot 插件
openclaw plugins install @tencent-connect/openclaw-qqbot@latest

# 添加 QQBot 渠道（示例 token）
openclaw channels add --channel qqbot --token "1903371205:QE3siYPG80tmgaVQMJGECBAAABCEGJMQ"

# 应用后重启 Gateway
openclaw gateway restart
```

## 十二、其他辅助命令记录

```bash
# 查看内核版本
uname -r

# 列出当前目录
ls

# 退出当前 shell
exit

# 检查 apt/dpkg 是否仍在运行（排查锁问题）
ps -ef | grep apt
ps -ef | grep dpkg

# 某些终端中的错误输入（ext）可以忽略
ext
```

