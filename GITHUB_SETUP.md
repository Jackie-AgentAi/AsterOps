# GitHub 仓库设置指南

## 📋 当前状态

✅ Git 仓库已初始化  
✅ 代码已提交到本地仓库（511个文件）  
✅ 默认分支：`main`  
✅ 提交信息：Initial commit: LLMOps运营管理平台

## 🚀 上传到 GitHub 的步骤

### 方法一：使用命令行（推荐）

#### 1. 在 GitHub 上创建新仓库

1. 访问 https://github.com/new
2. 填写仓库信息：
   - **Repository name**: `AsterOps` (或你喜欢的名称)
   - **Description**: `LLMOps运营管理平台 - 基于微服务架构的LLM运营管理平台`
   - **Visibility**: 选择 Public 或 Private
   - **⚠️ 重要**: 不要勾选 "Initialize this repository with a README"（因为我们已经有了）
3. 点击 "Create repository"

#### 2. 添加远程仓库并推送

在项目目录下执行以下命令（将 `YOUR_USERNAME` 替换为你的 GitHub 用户名）：

```bash
cd /data/AsterOps

# 添加远程仓库
git remote add origin https://github.com/YOUR_USERNAME/AsterOps.git

# 或者使用 SSH（如果你配置了 SSH 密钥）
# git remote add origin git@github.com:YOUR_USERNAME/AsterOps.git

# 推送代码到 GitHub
git push -u origin main
```

#### 3. 输入 GitHub 凭证

- 如果使用 HTTPS，会提示输入用户名和密码（或 Personal Access Token）
- 如果使用 SSH，确保已配置 SSH 密钥

### 方法二：使用 GitHub CLI（如果已安装）

```bash
# 安装 GitHub CLI（如果未安装）
# Ubuntu/Debian:
# sudo apt install gh

# 登录 GitHub
gh auth login

# 创建仓库并推送
cd /data/AsterOps
gh repo create AsterOps --public --source=. --remote=origin --push
```

## 🔐 GitHub 认证设置

### 使用 Personal Access Token（推荐）

1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token" → "Generate new token (classic)"
3. 设置权限：
   - ✅ `repo` (完整仓库访问权限)
4. 生成并复制 token
5. 推送时使用 token 作为密码

### 使用 SSH 密钥（推荐用于长期使用）

```bash
# 生成 SSH 密钥（如果还没有）
ssh-keygen -t ed25519 -C "your_email@example.com"

# 复制公钥
cat ~/.ssh/id_ed25519.pub

# 添加到 GitHub
# 访问 https://github.com/settings/keys
# 点击 "New SSH key"，粘贴公钥内容
```

## 📝 后续操作

### 日常推送代码

```bash
# 添加更改
git add .

# 提交更改
git commit -m "描述你的更改"

# 推送到 GitHub
git push origin main
```

### 查看远程仓库信息

```bash
# 查看远程仓库
git remote -v

# 查看分支
git branch -a

# 查看提交历史
git log --oneline
```

## ⚠️ 注意事项

1. **敏感信息**: 确保 `.gitignore` 已正确配置，避免提交：
   - `.env` 文件
   - 数据库数据文件
   - 日志文件
   - 密钥和证书

2. **大文件**: 如果仓库很大，考虑使用 Git LFS：
   ```bash
   git lfs install
   git lfs track "*.bin"
   git add .gitattributes
   ```

3. **私有仓库**: 如果包含敏感代码，建议使用 Private 仓库

## 🎯 快速命令参考

```bash
# 检查状态
git status

# 查看提交历史
git log --oneline -10

# 添加所有更改
git add .

# 提交更改
git commit -m "提交信息"

# 推送到 GitHub
git push origin main

# 拉取最新更改
git pull origin main
```

## 📞 需要帮助？

如果遇到问题，可以：
1. 查看 Git 文档：https://git-scm.com/doc
2. 查看 GitHub 文档：https://docs.github.com
3. 检查错误信息并搜索解决方案

---

**当前仓库状态**: ✅ 已准备好推送到 GitHub  
**下一步**: 在 GitHub 上创建仓库，然后执行 `git remote add origin` 和 `git push` 命令
