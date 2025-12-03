# 🚀 Simple Transfer - 轻量级仓库同步

**超简单的 Git 仓库同步工具 - 无需复杂配置！**

---

## ✨ 特点

- ✅ **极简设计** - 单个 Python 脚本，200 行代码
- ✅ **无依赖** - 只需要 Python 3 和 Git LFS
- ✅ **完整功能** - 支持 Git LFS 全量同步
- ✅ **批量支持** - 一次同步多个仓库
- ✅ **实时输出** - 流式显示进度
- ✅ **云端执行** - GitHub Actions 免费运行

---

## 🎯 快速开始（3 步）

### 步骤 1: 配置 GitHub Secrets

访问：`https://github.com/YOUR_USERNAME/models_transfer/settings/secrets/actions`

添加这些密钥：

| Name | Value | 必需 |
|------|-------|------|
| `HF_USERNAME` | HuggingFace 用户名 | ❌ 可选（公开仓库） |
| `HF_TOKEN` | HuggingFace Token | ❌ 可选（公开仓库） |
| `TARGET_USERNAME` | 目标平台用户名 | ✅ 必需 |
| `TARGET_TOKEN` | 目标平台 Token | ✅ 必需 |

---

### 步骤 2: 运行 Workflow

1. 访问：`https://github.com/YOUR_USERNAME/models_transfer/actions`

2. 点击左侧 `Simple Repository Transfer`

3. 点击 `Run workflow`

4. 在 `Repository pairs` 输入框中输入（每行一个配对）：

```
https://huggingface.co/internlm/Intern-S1|https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
https://huggingface.co/internlm/Intern-S1-mini|https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1-mini.git
```

5. 点击绿色的 `Run workflow` 按钮

---

### 步骤 3: 观察进度

在 Actions 页面查看实时日志：

```
📦 Transferring Repository
======================================================================
Source: https://huggingface.co/internlm/Intern-S1
Target: https://nm.aihuanxin.cn/.../Intern-S1.git

📥 Step 1/4: Cloning source repository...
→ git clone https://...
Cloning into 'repo'...
Receiving objects: 45% (234/520), 12.34 GB | 5.67 MB/s

📦 Step 2/4: Fetching Git LFS files...
→ git lfs fetch --all
Downloading LFS objects: 67% (345/520)

🔄 Step 3/4: Changing remote to target...
→ git remote remove origin
→ git remote add origin https://...

📤 Step 4/4: Pushing to target repository...
→ git lfs push origin --all
Uploading LFS objects: 89% (456/520)

✅ Transfer completed successfully!
```

---

## 📝 输入格式

### 格式 1: 源地址|目标地址（推荐）

```
https://huggingface.co/model1|https://target.com/model1.git
https://huggingface.co/model2|https://target.com/model2.git
```

### 格式 2: 支持注释

```
# 第一批模型
https://huggingface.co/model1|https://target.com/model1.git

# 第二批模型
https://huggingface.co/model2|https://target.com/model2.git
```

### 格式 3: 多行清晰格式

```
https://huggingface.co/internlm/Intern-S1 | https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git

https://huggingface.co/internlm/Intern-S1-mini | https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1-mini.git
```

**注意：** 使用 `|` 分隔源和目标地址

---

## 💻 本地使用

### 方法 1: 直接运行

```bash
# 设置环境变量
export TARGET_USERNAME="your_username"
export TARGET_TOKEN="your_token"

# 单个仓库
python3 simple_transfer.py \
  "https://huggingface.co/gpt2" \
  "https://target.com/gpt2.git"

# 多个仓库
python3 simple_transfer.py \
  "https://huggingface.co/model1" "https://target.com/model1.git" \
  "https://huggingface.co/model2" "https://target.com/model2.git"
```

### 方法 2: 使用 .env 文件

创建 `.env` 文件：

```bash
HF_USERNAME=your_hf_username
HF_TOKEN=hf_your_token
TARGET_USERNAME=your_target_username
TARGET_TOKEN=your_target_token
```

加载并运行：

```bash
source .env

python3 simple_transfer.py \
  "https://huggingface.co/model" \
  "https://target.com/model.git"
```

---

## 🔧 工作原理

### 4 步同步流程

```
┌─────────────────────────────────────────────┐
│  Step 1: Clone source repository            │
│  git clone https://huggingface.co/model     │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│  Step 2: Fetch all LFS files               │
│  git lfs fetch --all                        │
│  git lfs checkout                           │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│  Step 3: Change remote                      │
│  git remote remove origin                   │
│  git remote add origin https://target.com   │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│  Step 4: Push to target                     │
│  git lfs push origin --all                  │
│  git push -u origin main --force            │
└─────────────────────────────────────────────┘
```

### 认证处理

```python
# 自动将 Token 注入 URL
source: https://huggingface.co/model
        ↓
source: https://user:token@huggingface.co/model

target: https://target.com/model.git
        ↓
target: https://user:token@target.com/model.git
```

---

## 📊 性能对比

| 功能 | Simple Transfer | 完整版（batch_transfer） |
|------|----------------|--------------------------|
| 脚本大小 | 200 行 | 800+ 行 |
| 依赖 | 无 | python-dotenv, requests |
| 配置复杂度 | ⭐ 简单 | ⭐⭐⭐ 中等 |
| 全量同步 | ✅ | ✅ |
| 批量同步 | ✅ | ✅ |
| 实时日志 | ✅ | ✅ |
| Xget 加速 | ❌ | ✅ |
| Mirror 模式 | ❌ | ✅ |
| 指针模式 | ❌ | ✅ |
| 远程镜像 | ❌ | ✅ |
| 适用场景 | 简单迁移 | 复杂需求 |

---

## 📖 使用示例

### 示例 1: 单个模型

**输入：**
```
https://huggingface.co/gpt2|https://target.com/gpt2.git
```

**预计时间：** 5-15 分钟（小模型）

---

### 示例 2: 两个大模型

**输入：**
```
https://huggingface.co/internlm/Intern-S1|https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
https://huggingface.co/internlm/Intern-S1-mini|https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1-mini.git
```

**预计时间：** 60-120 分钟（含 LFS）

---

### 示例 3: 批量小模型

**输入：**
```
https://huggingface.co/bert-base-uncased|https://target.com/bert.git
https://huggingface.co/roberta-base|https://target.com/roberta.git
https://huggingface.co/distilbert-base|https://target.com/distilbert.git
```

**预计时间：** 10-30 分钟

---

## 🛠️ 故障排查

### 问题 1: "No space left on device"

**解决：** Workflow 已包含磁盘清理步骤，释放 20-30 GB

如果仍不够，分批传输：
```
# 第一次运行
https://huggingface.co/model1|https://target.com/model1.git

# 第二次运行
https://huggingface.co/model2|https://target.com/model2.git
```

---

### 问题 2: "Authentication failed"

**检查：**
1. GitHub Secrets 是否正确配置
2. Token 是否有正确的权限
3. Token 是否过期

**解决：**
重新生成 Token 并更新 Secrets

---

### 问题 3: 传输卡住

**可能原因：**
- 正在下载大文件（正常）
- 网络波动（等待恢复）

**处理：**
1. 等待 10-15 分钟
2. 查看是否有进度更新
3. 如果超过 30 分钟无变化，取消重试

---

### 问题 4: "LFS push failed"

**可能原因：**
- 目标仓库 LFS 配额不足
- 网络超时

**解决：**
1. 检查目标平台 LFS 配额
2. 重新运行 workflow（会从断点继续）

---

## 🔒 安全最佳实践

### ✅ 应该做的

1. **使用 GitHub Secrets 存储 Token**
   - 永远不要在代码中硬编码
   - 不要在日志中打印 Token

2. **定期轮换 Token**
   - 每 3-6 个月更换
   - 泄露后立即撤销

3. **最小权限原则**
   - 只授予必要的权限
   - 使用只读 Token 进行克隆

### ❌ 不应该做的

1. ❌ 在 workflow 输入中包含 Token
2. ❌ 提交包含 Token 的文件到 Git
3. ❌ 在公开 Issue 中讨论 Token

---

## 🆚 与完整版对比

### 何时使用 Simple Transfer？

✅ **适合：**
- 快速一次性迁移
- 简单的仓库同步
- 不需要高级功能
- 想要最简单的配置

### 何时使用完整版？

✅ **适合：**
- 需要 Xget 加速
- 需要 Mirror 模式
- 需要指针模式
- 频繁批量同步
- 需要详细日志和统计

---

## 📦 文件清单

```
simple_transfer.py              # Python 脚本（200 行）
.github/workflows/
  └── simple_transfer.yml       # GitHub Actions 配置（80 行）
```

**总共：** 280 行代码，极简设计！

---

## 🚀 升级到完整版

如果需要更多功能，可以切换到完整版：

```bash
# 使用完整版
./batch_transfer_optimized.sh \
  --config batch_config.txt \
  --use-xget \
  --mirror
```

查看完整版文档：
- [GITHUB_ACTIONS_GUIDE.md](GITHUB_ACTIONS_GUIDE.md)
- [BATCH_TRANSFER_GUIDE.md](BATCH_TRANSFER_GUIDE.md)

---

## 💡 技巧和提示

### 技巧 1: 测试小模型

先用小模型测试配置是否正确：

```
https://huggingface.co/gpt2|https://target.com/test-gpt2.git
```

成功后再传输大模型。

---

### 技巧 2: 分时段传输

避开高峰期：
- 推荐：凌晨或周末
- 避免：工作日白天

---

### 技巧 3: 监控进度

在 Actions 页面搜索关键字：
- `Receiving objects` - 克隆进度
- `Downloading` - LFS 下载
- `Uploading` - LFS 上传
- `✅` - 成功标记

---

## 📞 需要帮助？

- 📖 [README.md](README.md) - 项目总览
- 🐛 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 故障排查
- 💾 [DISK_SPACE_QUICK_FIX.md](DISK_SPACE_QUICK_FIX.md) - 空间问题

---

## ✨ 总结

**Simple Transfer = 最简单的 Git 仓库同步方案**

- 🎯 **3 步启动** - 配置 Secrets → 输入仓库 → 运行
- ⚡ **极速配置** - 无需复杂的配置文件
- 🔄 **批量支持** - 一次同步多个仓库
- ☁️ **云端运行** - GitHub Actions 免费执行
- 📊 **实时反馈** - 流式显示进度

**立即开始：**
```
访问 Actions → Simple Repository Transfer → Run workflow
```

**最后更新：** December 2025

