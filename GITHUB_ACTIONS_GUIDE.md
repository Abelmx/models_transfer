# GitHub Actions 批量传输指南

使用 GitHub Actions 在云端执行模型传输，完全绕过本地网络限制。

## 为什么选择 GitHub Actions？

✅ **免费额度充足**: 每月 2000 分钟（付费用户 3000 分钟）  
✅ **无需本地运行**: 完全在 GitHub 服务器上执行  
✅ **高速网络**: GitHub 服务器网络速度快，直连 HuggingFace 和目标平台  
✅ **自动化**: 可以设置定时任务或手动触发  
✅ **日志保存**: 自动保存详细日志，方便排查问题  

---

## 快速开始

### 步骤 1: 配置 GitHub Secrets

在你的 GitHub 仓库中配置敏感信息（不会暴露在代码中）：

1. 访问你的仓库：`https://github.com/Abelmx/models_transfer`
2. 点击 `Settings` → `Secrets and variables` → `Actions`
3. 点击 `New repository secret` 添加以下密钥：

| Secret 名称 | 值 | 说明 |
|------------|-----|------|
| `HF_TOKEN` | `hf_your_token_here` | HuggingFace Token（可选，公开仓库不需要） |
| `HF_USERNAME` | `your_username` | HuggingFace 用户名（可选） |
| `TARGET_TOKEN` | `glpat-xxx` | 目标平台 Token（**必需**） |
| `TARGET_USERNAME` | `maoxin` | 目标平台用户名（**必需**） |
| `TARGET_BASE_URL` | `https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin` | 目标仓库基础 URL（**必需**） |

**示例：**

```
TARGET_BASE_URL: https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin
```

这样，`batch_config.txt` 中的 `internlm/Intern-S1` 会被推送到：
```
https://maoxin:glpat-xxx@nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
```

> ⚠️ **安全提示**: 永远不要在代码中硬编码 Token！使用 GitHub Secrets 保护敏感信息。

---

### 步骤 2: 编辑 batch_config.txt

编辑 `batch_config.txt` 文件，添加要传输的模型：

```bash
# 格式: source_repo
# 会自动使用 TARGET_BASE_URL + 模型名称

internlm/Intern-S1
internlm/Intern-S1-mini
```

**或者使用完整格式：**

```bash
# 格式: source_repo|target_url
internlm/Intern-S1|https://target.com/Intern-S1.git
internlm/Intern-S1-mini|https://target.com/Intern-S1-mini.git
```

---

### 步骤 3: 推送到 GitHub

```bash
cd /home/maoxin/transfer

# 添加更改
git add batch_config.txt .github/workflows/batch_transfer.yml

# 提交
git commit -m "Configure batch transfer for GitHub Actions"

# 推送
git push origin main
```

---

### 步骤 4: 手动触发任务

1. 访问你的仓库 Actions 页面：  
   `https://github.com/Abelmx/models_transfer/actions`

2. 在左侧选择 `Batch Model Transfer`

3. 点击右侧的 `Run workflow` 按钮

4. 配置运行参数：
   - **Use Xget acceleration**: `true`（推荐，3-15x 加速）
   - **Enable mirror mode**: `false`（通常不需要）
   - **Ignore LFS files**: `false`（完整传输）
   - **Skip LFS push errors**: `false`（正常模式）
   - **Delay between models**: `60`（秒，避免速率限制）
   - **Max retry attempts**: `3`（失败重试次数）

5. 点击绿色的 `Run workflow` 按钮开始执行

---

## 监控执行过程

### 实时查看日志

1. 在 Actions 页面，点击正在运行的 workflow
2. 点击 `transfer` job
3. 展开各个步骤查看实时日志

### 下载详细日志

任务完成后（成功或失败），会自动上传日志文件：

1. 在 workflow 运行页面，滚动到底部
2. 找到 `Artifacts` 区域
3. 下载 `transfer-logs-XXX.zip`
4. 解压查看详细日志

---

## 高级配置

### 定时自动执行

编辑 `.github/workflows/batch_transfer.yml`，取消注释 `schedule` 部分：

```yaml
on:
  workflow_dispatch:
    # ... 手动触发配置 ...
  
  schedule:
    - cron: '0 2 * * 0'  # 每周日凌晨 2 点执行
```

**常用 Cron 表达式：**

| 表达式 | 说明 |
|-------|------|
| `0 2 * * *` | 每天凌晨 2 点 |
| `0 2 * * 0` | 每周日凌晨 2 点 |
| `0 2 1 * *` | 每月 1 号凌晨 2 点 |
| `0 */6 * * *` | 每 6 小时一次 |

---

### 分阶段传输策略

**阶段 1: 快速传输文本文件**

触发参数：
- Ignore LFS files: `true`
- Delay: `30`

批量快速建立仓库结构（1-2 分钟/模型）。

**阶段 2: 完整传输（包含模型权重）**

触发参数：
- Ignore LFS files: `false`
- Use Xget acceleration: `true`
- Delay: `120`（避免速率限制）
- Max retry attempts: `5`

完整传输所有模型文件（30-60 分钟/模型）。

---

### 只传输特定模型

创建多个配置文件：

**batch_config_priority.txt**（高优先级）:
```
internlm/Intern-S1
```

**batch_config_remaining.txt**（低优先级）:
```
internlm/Intern-S1-mini
other-org/other-model
```

修改 workflow 手动指定配置文件，或创建多个 workflow 文件。

---

## 故障排查

### 问题 1: Secrets 未配置

**错误信息：**
```
Error: No target URL specified and no target-base set
```

**解决：**
1. 检查 GitHub Secrets 是否正确配置
2. 确保 `TARGET_BASE_URL` 拼写正确
3. 重新运行 workflow

---

### 问题 2: Token 权限不足

**错误信息：**
```
fatal: Authentication failed
remote: GitLab: You are not allowed to push code to this project.
```

**解决：**
1. 确认 `TARGET_TOKEN` 有 `write_repository` 权限
2. 在目标平台重新生成 Token
3. 更新 GitHub Secret 中的 `TARGET_TOKEN`

---

### 问题 3: 磁盘空间不足

**错误信息：**
```
error: no space left on device
fatal: cannot copy ... to ...: No space left on device
```

**原因：** GitHub Actions 免费 runner 只有约 10GB 可用空间，大型模型（如 Intern-S1 30GB）会超出限制。

**解决方案（已自动配置）：**

Workflow 已添加**自动磁盘清理步骤**，会释放 20-30GB 空间：
- 删除 .NET SDK (~2.8 GB)
- 删除 Android SDK (~11 GB)
- 删除 GHC (~2.5 GB)
- 删除 CodeQL (~5 GB)
- 清理后可用空间：~35 GB ✅

**验证清理是否成功：**

在 Actions 日志中搜索 "After cleanup"：
```
After cleanup:
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        84G   12G   72G  15% /
```

如果 `Avail` 列显示 > 30 GB，说明清理成功，可以传输 Intern-S1。

**其他解决方案：**

如果仍然空间不足，查看详细方案：
📖 [GITHUB_ACTIONS_DISK_SPACE.md](GITHUB_ACTIONS_DISK_SPACE.md)

---

### 问题 4: 超时（6 小时限制）

**错误信息：**
```
The job running on runner ... has exceeded the maximum execution time of 360 minutes.
```

**解决方案：**

**方案 1: 分批传输**
```bash
# batch_config_part1.txt
internlm/Intern-S1

# batch_config_part2.txt
internlm/Intern-S1-mini
```

分两次运行，每次一个模型。

**方案 2: 使用 --ignore-lfs 先建立结构**
- 第一次运行：`Ignore LFS files: true`（快速）
- 第二次运行：`Ignore LFS files: false`（完整，可以分批）

**方案 3: 增加延迟**
```
Delay between models: 300  # 5 分钟延迟，避免速率限制导致重试
```

---

### 问题 4: HTTP 429 速率限制

**错误信息：**
```
error: RPC failed; HTTP 429
```

**解决：**
1. 增加 `Delay between models` 到 120-300 秒
2. 减少每次传输的模型数量
3. 等待几小时后重试

---

## 成本和限制

### GitHub Actions 免费额度

| 账户类型 | 每月分钟数 | 并发任务 | 单次最长时间 |
|---------|-----------|---------|------------|
| 免费账户 | 2000 分钟 | 20 | 6 小时 |
| Pro 账户 | 3000 分钟 | 40 | 6 小时 |
| Team 账户 | 3000 分钟/用户 | 60 | 6 小时 |

**实际使用估算（基于 Intern-S1 30GB）：**

| 模式 | 时间/模型 | 可传输数量（2000分钟） |
|------|----------|---------------------|
| 完整传输 + Xget | ~45 分钟 | 约 44 个模型 |
| 文本传输 | ~2 分钟 | 约 1000 个模型 |
| 指针传输 | ~5 分钟 | 约 400 个模型 |

---

## 最佳实践

### 1. 先测试单个模型

创建 `batch_config_test.txt`:
```
gpt2  # 小模型，快速测试
```

运行一次确保配置正确。

---

### 2. 使用 Xget 加速

始终启用 `Use Xget acceleration: true`，可获得 3-15x 加速。

---

### 3. 合理设置延迟

- 小模型（< 1GB）：30 秒
- 中等模型（1-10GB）：60 秒
- 大模型（> 10GB）：120-300 秒

---

### 4. 启用错误继续

始终启用 `--continue-on-error`，避免一个失败导致全部停止。

---

### 5. 定期检查日志

下载并保存 Artifacts 中的日志文件，便于追踪历史记录。

---

## 与本地执行对比

| 特性 | 本地执行 | GitHub Actions |
|------|---------|---------------|
| 网络速度 | 受限于本地网络 | ✅ GitHub 数据中心高速网络 |
| 稳定性 | 需要保持电脑开机 | ✅ 云端持续运行 |
| 成本 | 消耗本地带宽和电力 | ✅ 免费（有额度） |
| 日志 | 需要手动保存 | ✅ 自动保存 30 天 |
| 并发 | 受限于本地资源 | ✅ 可运行多个任务 |
| 安全性 | Token 存在本地 | ✅ GitHub Secrets 加密 |

---

## 完整示例

### 场景：传输 Intern-S1 和 Intern-S1-mini

**batch_config.txt:**
```
internlm/Intern-S1
internlm/Intern-S1-mini
```

**GitHub Secrets 配置:**
```
TARGET_TOKEN: glpat-YourRealTokenHere
TARGET_USERNAME: maoxin
TARGET_BASE_URL: https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin
```

**Workflow 参数:**
```
Use Xget acceleration: true
Ignore LFS files: false
Delay between models: 120
Max retry attempts: 3
```

**预期结果:**
- Intern-S1: 约 45-60 分钟
- Intern-S1-mini: 约 15-30 分钟
- 总计: 约 60-90 分钟

**推送到:**
- `https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git`
- `https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1-mini.git`

---

## 相关文档

- [README.md](README.md) - 项目完整说明
- [BATCH_TRANSFER_GUIDE.md](BATCH_TRANSFER_GUIDE.md) - 批处理详细指南
- [STAGED_TRANSFER_GUIDE.md](STAGED_TRANSFER_GUIDE.md) - 分阶段传输策略
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 故障排查

---

## 常见问题

**Q: GitHub Actions 会消耗我的仓库配额吗？**  
A: 会。公开仓库免费，私有仓库消耗账户配额（免费账户 2000 分钟/月）。

**Q: 可以同时运行多个 workflow 吗？**  
A: 可以。免费账户最多 20 个并发任务。

**Q: Token 安全吗？**  
A: 安全。GitHub Secrets 使用加密存储，不会在日志中显示。

**Q: 任务失败了会重试吗？**  
A: 会。`max_retries` 参数控制每个模型的重试次数（默认 3 次）。

**Q: 可以取消正在运行的任务吗？**  
A: 可以。在 Actions 页面点击 `Cancel workflow` 按钮。

---

**最后更新:** December 2025

