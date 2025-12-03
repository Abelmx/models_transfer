# ⚠️ 安全警告 - Security Warning

## 🔴 重要：永远不要在代码中硬编码敏感信息！

**警告示例：** 如果你在代码或消息中包含了真实的 Token（如 `glpat-xxxxxxxxxxxxxxxx`），这会是一个**严重的安全风险**！

---

## 立即采取的行动

### 1. 撤销泄露的 Token

1. 访问你的 GitLab 实例（如 `https://your-gitlab.com`）
2. 进入 `Settings` → `Access Tokens`
3. 找到可能泄露的 Token
4. 点击 `Revoke` 撤销该 Token
5. 创建新的 Token（不要分享给任何人）

### 2. 使用 GitHub Secrets 存储敏感信息

**正确做法：**

在 GitHub 仓库中配置 Secrets：

1. 访问：`https://github.com/Abelmx/models_transfer/settings/secrets/actions`
2. 点击 `New repository secret`
3. 添加以下 Secrets：

| Name | Value | 说明 |
|------|-------|------|
| `TARGET_TOKEN` | `glpat-新的token` | 你的新 GitLab Token |
| `TARGET_USERNAME` | `maoxin` | 用户名 |
| `TARGET_BASE_URL` | `https://nm.aihuanxin.cn/...` | 基础 URL（不含凭据） |

**错误做法（永远不要这样）：**

```bash
# ❌ 错误：硬编码在配置文件中
TARGET_URL="https://maoxin:glpat-xxx@nm.aihuanxin.cn/..."

# ❌ 错误：提交到 Git 仓库
git add .env  # .env 包含 Token

# ❌ 错误：在聊天、邮件、文档中分享
"我的 token 是 glpat-xxx"
```

---

## 配置 GitHub Secrets 的步骤

### 方法 1: 通过 GitHub Web 界面（推荐）

1. **访问 Secrets 设置页面**
   ```
   https://github.com/Abelmx/models_transfer/settings/secrets/actions
   ```

2. **添加 TARGET_BASE_URL**
   - Name: `TARGET_BASE_URL`
   - Value: `https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin`
   - 点击 `Add secret`

3. **添加 TARGET_USERNAME**
   - Name: `TARGET_USERNAME`
   - Value: `maoxin`
   - 点击 `Add secret`

4. **添加 TARGET_TOKEN**（最敏感）
   - Name: `TARGET_TOKEN`
   - Value: `glpat-新生成的token`（不要包含 `@` 符号）
   - 点击 `Add secret`

5. **（可选）添加 HuggingFace 凭据**
   - Name: `HF_TOKEN`
   - Value: `hf_你的token`
   - 点击 `Add secret`
   
   - Name: `HF_USERNAME`
   - Value: `你的用户名`
   - 点击 `Add secret`

### 方法 2: 通过 GitHub CLI（高级用户）

```bash
# 安装 GitHub CLI
# https://cli.github.com/

# 登录
gh auth login

# 设置 Secrets
gh secret set TARGET_BASE_URL -b "https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin"
gh secret set TARGET_USERNAME -b "maoxin"
gh secret set TARGET_TOKEN -b "glpat-新token"

# 可选：HuggingFace
gh secret set HF_TOKEN -b "hf_你的token"
gh secret set HF_USERNAME -b "你的用户名"
```

---

## 验证 Secrets 配置

配置完成后，在 GitHub Actions 中验证：

1. 访问 Actions 页面：
   ```
   https://github.com/Abelmx/models_transfer/actions
   ```

2. 运行 `Batch Model Transfer` workflow

3. 检查日志中的配置部分：
   ```
   Configuration:
     Target base URL:  ✅ (set from secret)
     Target username:  ✅ (set from secret)
     Target token:     ✅ (hidden)
   ```

如果看到 `(not set)` 或错误，说明 Secrets 配置不正确。

---

## 安全最佳实践

### ✅ 应该做的

1. **使用 GitHub Secrets 存储所有敏感信息**
   - Tokens
   - Passwords
   - API Keys

2. **使用 `.gitignore` 排除敏感文件**
   ```gitignore
   .env
   *.log
   *token*
   *secret*
   ```

3. **定期轮换 Tokens**
   - 每 3-6 个月更换一次
   - 泄露后立即更换

4. **最小权限原则**
   - 只授予必要的权限
   - 对于只读操作，使用只读 Token

5. **使用环境变量**
   ```bash
   # 正确
   export TARGET_TOKEN="$(cat ~/.secrets/gitlab_token)"
   python3 transfer.py
   ```

### ❌ 不应该做的

1. **在代码中硬编码**
   ```python
   # 错误示例
   token = "glpat-xxx"
   ```

2. **提交到 Git 仓库**
   ```bash
   # 错误示例
   git add .env
   git commit -m "Add credentials"
   ```

3. **在聊天/邮件中分享**
   - 不要在 Discord、Slack、Email 中发送 Token
   - 使用加密的密码管理工具（如 1Password、Bitwarden）

4. **在日志中打印**
   ```python
   # 错误示例
   print(f"Token: {token}")
   ```

5. **使用弱权限的 Token 到处使用**
   - 为不同用途创建不同的 Token
   - 限制 Token 的过期时间

---

## 如果 Token 已泄露怎么办？

### 立即行动清单

- [ ] 撤销泄露的 Token
- [ ] 生成新的 Token
- [ ] 更新所有使用该 Token 的地方
- [ ] 检查是否有未授权访问（审计日志）
- [ ] 通知团队成员
- [ ] 审查其他可能泄露的凭据

### GitLab Token 撤销步骤

1. 登录 GitLab：`https://nm.aihuanxin.cn`
2. 点击右上角头像 → `Preferences`
3. 左侧菜单 → `Access Tokens`
4. 找到泄露的 Token，点击 `Revoke`
5. 创建新 Token：
   - Name: `models_transfer_github_actions`
   - Expiration date: 90 天后
   - Scopes: 
     - ✅ `write_repository`
     - ✅ `read_repository`
   - 点击 `Create personal access token`
6. 复制新 Token（只会显示一次）
7. 更新 GitHub Secret 中的 `TARGET_TOKEN`

---

## 检查你的仓库是否安全

### 扫描历史提交中的敏感信息

```bash
# 使用 git-secrets 工具
# https://github.com/awslabs/git-secrets

# 安装
git clone https://github.com/awslabs/git-secrets.git
cd git-secrets
sudo make install

# 扫描
cd /home/maoxin/transfer
git secrets --scan-history
```

### 使用 GitHub 的 Secret Scanning

GitHub 会自动扫描你的仓库中的已知 Token 格式。如果发现，会发送警告邮件。

---

## 配置完成检查清单

验证你的配置：

- [ ] ✅ 旧的泄露 Token 已撤销
- [ ] ✅ 新 Token 已生成
- [ ] ✅ GitHub Secrets 已配置：
  - [ ] `TARGET_BASE_URL`
  - [ ] `TARGET_USERNAME`
  - [ ] `TARGET_TOKEN`
- [ ] ✅ `batch_config.txt` 不包含凭据
- [ ] ✅ `.gitignore` 包含 `.env`
- [ ] ✅ 本地 `.env` 文件未提交到 Git
- [ ] ✅ GitHub Actions workflow 测试通过

---

## 相关资源

- [GitHub Secrets 文档](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitLab Personal Access Tokens](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html)
- [OWASP 密钥管理最佳实践](https://cheatsheetseries.owasp.org/cheatsheets/Key_Management_Cheat_Sheet.html)

---

## 联系支持

如果你发现任何安全问题或需要帮助，请：

1. **不要在公开的 Issue 中讨论敏感信息**
2. 使用 GitHub Security Advisories（私密）
3. 或直接联系仓库维护者

---

**记住：安全无小事，谨慎处理所有凭据！** 🔐

**最后更新:** December 2025

