# Staged Transfer Guide - 分阶段传输指南

分阶段传输功能允许你更精细地控制 Git LFS 文件的处理方式。

## 两个新增的 Flag

### 1. `--ignore-lfs` - 完全忽略 LFS 文件

**功能：** 忽略所有 Git LFS 托管的文件（包括指针文件），仅克隆和推送普通 Git 文件。

**使用场景：**

- 你只需要代码、配置文件、README 等文本文件
- 不需要模型权重等大文件
- 想快速镜像仓库结构而不传输实际的模型数据
- 目标平台暂时不支持 LFS 或需要分开处理

**工作原理：**

1. 正常克隆源仓库
2. 自动卸载 Git LFS 追踪
3. 删除 `.gitattributes` 中的 LFS 配置
4. 移除所有 LFS 指针文件
5. 提交更改（仓库中不再包含任何 LFS 引用）
6. 推送到目标仓库（纯 Git 仓库，无 LFS）

**示例：**

```bash
# 单个模型传输（仅文本文件）
python3 transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://target.com/Intern-S1.git \
  --ignore-lfs

# 批量传输（仅文本文件）
./batch_transfer_optimized.sh \
  --ignore-lfs \
  --config models_list.txt
```

**预期结果：**

- ✅ 传输速度极快（只有文本文件，通常 < 10MB）
- ✅ 目标仓库不需要 LFS 支持
- ❌ 目标仓库中没有模型权重文件
- ❌ 无法直接加载模型（缺少权重）

**适用于：**

- 仓库结构预览
- 文档和代码审查
- 分布式团队协作（文本文件先行）
- 临时备份元数据

---

### 2. `--skip-lfs-errors` - 跳过 LFS 推送错误

**功能：** 在 `GIT_LFS_SKIP_SMUDGE=1` 模式下（仅拉取指针），推送时忽略 LFS 对象缺失的错误，继续完成传输。

**使用场景：**

- 使用指针模式传输（`GIT_LFS_SKIP_SMUDGE=1`）
- 目标仓库与源仓库共享同一 LFS 存储后端
- 仅需要同步 Git 结构和 LFS 指针，不需要实际对象
- 允许 LFS 推送失败但继续完成 Git 推送

**工作原理：**

1. 克隆源仓库（带 `GIT_LFS_SKIP_SMUDGE=1`，只获取指针）
2. 尝试推送 LFS 对象到目标（可能失败，因为本地没有实际对象）
3. **捕获 LFS 推送错误，继续执行**（而不是退出）
4. 推送 Git refs（分支、标签等）
5. 传输完成（包含指针，但可能缺少 LFS 对象）

**示例：**

```bash
# 在 .env 中设置
GIT_LFS_SKIP_SMUDGE=1

# 传输（仅指针 + 跳过 LFS 错误）
python3 transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://target.com/Intern-S1.git \
  --skip-lfs-errors

# 批量传输
./batch_transfer_optimized.sh \
  --skip-lfs-errors \
  --config models_list.txt
```

**预期结果：**

- ✅ Git 结构完整传输（分支、标签、提交历史）
- ✅ LFS 指针文件已推送
- ⚠️ LFS 对象可能缺失（取决于目标仓库配置）
- ⚠️ 克隆目标仓库时可能需要额外配置 LFS 存储

**适用于：**

- 多个 Git 远程共享同一 LFS 存储
- 仅同步元数据和版本历史
- 快速迁移（不下载大文件）
- LFS 对象将通过其他方式同步

---

## 使用场景对比

| 场景 | 推荐 Flag | 说明 |
|------|-----------|------|
| 完整传输（包含 LFS 对象） | 无需 flag | 默认行为，最完整 |
| 仅传输文本文件（无 LFS） | `--ignore-lfs` | 最快，目标无 LFS |
| 传输指针（共享 LFS 后端） | `--skip-lfs-errors` | 需配合 `GIT_LFS_SKIP_SMUDGE=1` |
| 传输指针（独立 LFS 后端） | `GIT_LFS_SKIP_SMUDGE=1`（无额外 flag） | 会推送指针但可能失败 |

---

## 三种传输模式详解

### 模式 1: 完整传输（默认）

```bash
# .env 配置
GIT_LFS_SKIP_SMUDGE=0  # 或不设置

# 命令
python3 transfer.py \
  --source https://huggingface.co/model \
  --target https://target.com/model.git
```

**流程：**
1. 克隆仓库（包含 LFS 对象）
2. 拉取所有 LFS 文件到本地
3. 推送 LFS 对象到目标
4. 推送 Git refs 到目标

**结果：** 目标仓库是源仓库的完整副本

**时间：** 最慢（需下载所有大文件）

**流量：** 最大

---

### 模式 2: 仅文本文件（`--ignore-lfs`）

```bash
# .env 配置
# 任意（LFS 设置会被忽略）

# 命令
python3 transfer.py \
  --source https://huggingface.co/model \
  --target https://target.com/model.git \
  --ignore-lfs
```

**流程：**
1. 克隆仓库
2. **移除所有 LFS 追踪**
3. **删除 LFS 指针文件**
4. 提交更改
5. 推送到目标（无 LFS 内容）

**结果：** 目标仓库只包含文本文件，无任何 LFS 引用

**时间：** 最快（< 1 分钟，通常）

**流量：** 最小（几 MB）

**限制：** 目标仓库无法加载模型

---

### 模式 3: 指针模式（`GIT_LFS_SKIP_SMUDGE=1` + `--skip-lfs-errors`）

```bash
# .env 配置
GIT_LFS_SKIP_SMUDGE=1

# 命令
python3 transfer.py \
  --source https://huggingface.co/model \
  --target https://target.com/model.git \
  --skip-lfs-errors
```

**流程：**
1. 克隆仓库（仅指针，不下载 LFS 对象）
2. 尝试推送 LFS 对象（失败 → 忽略）
3. 推送 Git refs 到目标（包含指针）

**结果：** 目标仓库包含 LFS 指针，但 LFS 对象可能缺失

**时间：** 快（不下载大文件）

**流量：** 小（仅 Git 元数据）

**限制：** 需要目标仓库配置 LFS 存储或与源共享

---

## 分阶段传输策略

### 策略 1: 先文本后模型

**适用场景：** 快速部署仓库结构，稍后补充模型文件

```bash
# 阶段 1: 传输文本文件（快速）
python3 transfer.py \
  --source https://huggingface.co/model \
  --target https://target.com/model.git \
  --ignore-lfs

# 团队可以立即访问代码和文档

# 阶段 2: 传输完整仓库（覆盖）
python3 transfer.py \
  --source https://huggingface.co/model \
  --target https://target.com/model.git

# 现在包含模型权重
```

**优点：**
- 快速提供访问
- 团队可以先审查代码
- 模型文件可以在非高峰期传输

---

### 策略 2: 先指针后对象

**适用场景：** 需要快速同步多个仓库结构

```bash
# 阶段 1: 同步指针（快速）
GIT_LFS_SKIP_SMUDGE=1 python3 transfer.py \
  --source https://huggingface.co/model \
  --target https://target.com/model.git \
  --skip-lfs-errors

# 阶段 2: 配置 LFS 存储
# （在目标平台手动配置 LFS 后端，指向源或独立存储）

# 阶段 3: 用户克隆时自动拉取 LFS 对象
git clone https://target.com/model.git
cd model
git lfs pull  # 从配置的 LFS 存储拉取
```

**优点：**
- 批量同步快速
- 灵活的 LFS 存储策略
- 按需下载大文件

---

### 策略 3: 批量多阶段

**适用场景：** 迁移大量模型仓库

```bash
# 阶段 1: 批量传输所有文本文件（快速建立结构）
./batch_transfer_optimized.sh \
  --ignore-lfs \
  --config all_models.txt \
  --continue-on-error

# 阶段 2: 选择性传输重要模型的完整版本
./batch_transfer_optimized.sh \
  --config important_models.txt \
  --delay 60

# 阶段 3: 传输其余模型（低优先级）
./batch_transfer_optimized.sh \
  --config remaining_models.txt \
  --delay 120 \
  --continue-on-error
```

**优点：**
- 优先级管理
- 分散网络负载
- 避免速率限制

---

## 最佳实践

### 1. 测试先行

```bash
# 先用小仓库测试
python3 transfer.py \
  --source https://huggingface.co/gpt2 \
  --target https://target.com/test-gpt2.git \
  --ignore-lfs

# 确认工作正常后再批量执行
```

### 2. 日志记录

```bash
# 记录详细日志
python3 transfer.py \
  --source ... \
  --target ... \
  --ignore-lfs \
  2>&1 | tee transfer_$(date +%Y%m%d_%H%M%S).log
```

### 3. 验证结果

```bash
# 检查目标仓库
git clone https://target.com/model.git test-clone
cd test-clone

# 检查是否有 LFS 文件
git lfs ls-files

# 如果用了 --ignore-lfs，应该为空
# 如果用了 --skip-lfs-errors，应该有指针
```

### 4. 错误处理

```bash
# 使用批处理脚本的错误处理功能
./batch_transfer_optimized.sh \
  --ignore-lfs \
  --continue-on-error \
  --max-retries 3 \
  --delay 30
```

---

## 常见问题

### Q1: `--ignore-lfs` 和 `GIT_LFS_SKIP_SMUDGE=1` 有什么区别？

**A:** 

- `GIT_LFS_SKIP_SMUDGE=1`: 克隆时保留指针文件，但不下载实际对象。仓库中仍然**有** LFS 引用。
- `--ignore-lfs`: 完全移除 LFS 追踪，删除指针文件。仓库中**没有** LFS 引用。

### Q2: 使用 `--ignore-lfs` 后能否恢复 LFS 文件？

**A:** 不能直接恢复。你需要：
1. 重新传输完整仓库（覆盖）
2. 或手动配置 LFS 并重新拉取

### Q3: `--skip-lfs-errors` 是否会影响 Git 推送？

**A:** 不会。它只影响 LFS 对象推送。Git refs（分支、标签）仍会正常推送。

### Q4: 哪种模式最省流量？

**A:** `--ignore-lfs` 最省流量，因为完全不传输 LFS 内容。

### Q5: 可以结合多个 flag 吗？

**A:** 可以部分结合：

```bash
# ✅ 有效组合
--ignore-lfs --mirror       # 镜像模式 + 无 LFS
--skip-lfs-errors --mirror  # 镜像模式 + 跳过 LFS 错误
--ignore-lfs --use-xget     # Xget 加速 + 无 LFS

# ❌ 无意义组合
--ignore-lfs --skip-lfs-errors  # 冲突（ignore 优先级更高）
```

---

## 性能对比

基于 `internlm/Intern-S1` 模型（约 30GB）：

| 模式 | 时间 | 流量 | 完整度 |
|------|------|------|--------|
| 完整传输 | ~45 分钟 | 30GB | 100% |
| 指针模式 + skip | ~5 分钟 | 50MB | Git 100%, LFS 0% |
| ignore-lfs | ~2 分钟 | 10MB | Git 100%, 无 LFS |

---

## 环境变量配置

```bash
# .env 文件配置示例

# 完整传输（默认）
GIT_LFS_SKIP_SMUDGE=0

# 指针模式
GIT_LFS_SKIP_SMUDGE=1

# HuggingFace 认证（可选，公开仓库不需要）
HF_TOKEN=hf_your_token
HF_USERNAME=your_username

# 目标平台认证（必需）
TARGET_TOKEN=your_target_token
TARGET_USERNAME=your_target_username
```

---

## 命令速查表

```bash
# 完整传输
python3 transfer.py -s SOURCE -t TARGET

# 仅文本文件
python3 transfer.py -s SOURCE -t TARGET --ignore-lfs

# 指针模式（需设置环境变量）
GIT_LFS_SKIP_SMUDGE=1 python3 transfer.py -s SOURCE -t TARGET --skip-lfs-errors

# 批量 - 仅文本
./batch_transfer_optimized.sh --ignore-lfs

# 批量 - 指针模式
./batch_transfer_optimized.sh --skip-lfs-errors

# 组合：镜像 + 无 LFS + Xget
python3 transfer.py -s SOURCE -t TARGET --mirror --ignore-lfs --use-xget
```

---

## 故障排查

### 问题 1: `--ignore-lfs` 后仍有 LFS 文件

**原因：** 可能是 `.gitattributes` 删除失败

**解决：**
```bash
cd <repo_path>
rm -f .gitattributes
git add .gitattributes
git commit -m "Remove LFS tracking"
```

### 问题 2: `--skip-lfs-errors` 后克隆失败

**原因：** 目标仓库没有 LFS 对象

**解决：**
```bash
# 方案 1: 重新完整传输
python3 transfer.py -s SOURCE -t TARGET

# 方案 2: 配置目标 LFS 存储
# 在目标平台配置 LFS 指向源或独立存储
```

### 问题 3: 传输时 LFS 推送卡住

**原因：** 大文件上传超时

**解决：**
```bash
# 增加 Git 超时时间
git config --global http.postBuffer 524288000
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999
```

---

**相关文档：**
- [QUICKSTART.md](QUICKSTART.md) - 快速开始
- [README.md](README.md) - 完整功能说明
- [BATCH_TRANSFER_GUIDE.md](BATCH_TRANSFER_GUIDE.md) - 批处理指南
- [AUTHENTICATION_GUIDE.md](AUTHENTICATION_GUIDE.md) - 认证配置

**最后更新：** December 2025

