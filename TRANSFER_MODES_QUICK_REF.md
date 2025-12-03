# Transfer Modes - Quick Reference Card

快速查找不同传输模式的使用方法。

## 三种传输模式

### 🚀 模式 1: 完整传输（默认）

**命令：**
```bash
python3 transfer.py -s SOURCE -t TARGET
```

**特点：**
- ✅ 传输所有内容（代码 + 模型权重）
- ✅ 目标仓库可直接使用
- ❌ 速度较慢（需下载大文件）
- ❌ 流量消耗大

**适用场景：** 生产环境部署

---

### ⚡ 模式 2: 仅文本文件

**命令：**
```bash
python3 transfer.py -s SOURCE -t TARGET --ignore-lfs
```

**特点：**
- ✅ 速度极快（1-2 分钟）
- ✅ 流量最小（通常 < 20MB）
- ✅ 目标仓库无需 LFS 支持
- ❌ 缺少模型权重文件

**适用场景：** 
- 快速预览仓库结构
- 代码审查
- 文档浏览

---

### 🔄 模式 3: 指针模式

**命令：**
```bash
# 在 .env 中设置
GIT_LFS_SKIP_SMUDGE=1

# 执行传输
python3 transfer.py -s SOURCE -t TARGET --skip-lfs-errors
```

**特点：**
- ✅ 速度快（5-10 分钟）
- ✅ 包含 LFS 指针
- ⚠️ LFS 对象需额外配置
- ⚠️ 目标仓库需要 LFS 后端

**适用场景：** 
- 多个仓库共享 LFS 存储
- 延迟加载大文件
- 分阶段部署

---

## 性能对比表

基于 30GB 模型（如 `internlm/Intern-S1`）：

| 模式 | 时间 | 流量 | 完整度 | 可用性 |
|------|------|------|--------|--------|
| **完整** | ~45min | 30GB | 100% | ✅ 立即可用 |
| **文本** | ~2min | 10MB | Git 100%<br>LFS 0% | ⚠️ 缺模型 |
| **指针** | ~5min | 50MB | Git 100%<br>LFS 指针 | ⚠️ 需配置 |

---

## 批处理模式

### 批量文本传输

```bash
./batch_transfer_optimized.sh \
  --ignore-lfs \
  --config models.txt \
  --continue-on-error
```

### 批量指针传输

```bash
# 在 .env 中设置
GIT_LFS_SKIP_SMUDGE=1

./batch_transfer_optimized.sh \
  --skip-lfs-errors \
  --config models.txt \
  --delay 30
```

### 批量完整传输

```bash
./batch_transfer_optimized.sh \
  --config models.txt \
  --delay 60 \
  --max-retries 3
```

---

## 分阶段策略

### 策略 1: 先文本后模型

```bash
# 阶段 1: 快速传输文本（1-2 分钟）
python3 transfer.py -s SOURCE -t TARGET --ignore-lfs

# 团队可以立即查看代码

# 阶段 2: 传输完整仓库（30-60 分钟）
python3 transfer.py -s SOURCE -t TARGET

# 现在包含模型权重
```

**优势：** 快速部署，团队可先审查代码

---

### 策略 2: 批量分阶段

```bash
# 阶段 1: 所有仓库文本（快速建立结构）
./batch_transfer_optimized.sh --ignore-lfs --config all_models.txt

# 阶段 2: 重要模型完整传输
./batch_transfer_optimized.sh --config important_models.txt

# 阶段 3: 其余模型（低优先级）
./batch_transfer_optimized.sh --config remaining_models.txt --delay 120
```

**优势：** 优先级管理，分散负载

---

## 环境变量配置

### 完整模式 (.env)

```bash
# HuggingFace（公开仓库可选）
HF_TOKEN=hf_your_token  # 或留空
HF_USERNAME=username    # 或留空

# 目标平台（必需）
TARGET_TOKEN=your_token
TARGET_USERNAME=username

# LFS 配置
GIT_LFS_SKIP_SMUDGE=0  # 或不设置
```

### 指针模式 (.env)

```bash
# HuggingFace
HF_TOKEN=hf_your_token
HF_USERNAME=username

# 目标平台
TARGET_TOKEN=your_token
TARGET_USERNAME=username

# LFS 配置（关键！）
GIT_LFS_SKIP_SMUDGE=1  # 启用指针模式
```

---

## 常见组合

### 1. 快速预览 + Xget 加速

```bash
python3 transfer.py -s SOURCE -t TARGET \
  --ignore-lfs \
  --use-xget
```

**用途：** 最快速度查看仓库结构

---

### 2. 镜像模式 + 仅文本

```bash
python3 transfer.py -s SOURCE -t TARGET \
  --mirror \
  --ignore-lfs
```

**用途：** 完整 Git 历史（无大文件）

---

### 3. 批量 + 指针 + 错误继续

```bash
GIT_LFS_SKIP_SMUDGE=1 ./batch_transfer_optimized.sh \
  --skip-lfs-errors \
  --continue-on-error \
  --delay 30 \
  --config models.txt
```

**用途：** 批量快速同步结构

---

## 故障排查

### 问题：`--ignore-lfs` 后仍有 LFS 文件

**原因：** Git LFS 未正确卸载

**解决：**
```bash
cd <repo>
git lfs uninstall
rm -f .gitattributes
```

---

### 问题：`--skip-lfs-errors` 推送失败

**原因：** 目标没有 LFS 对象

**解决：**
```bash
# 方案 1: 完整传输
python3 transfer.py -s SOURCE -t TARGET

# 方案 2: 配置目标 LFS 存储
```

---

### 问题：HTTP 429 Too Many Requests

**原因：** 请求过于频繁

**解决：**
```bash
# 方案 1: 添加延迟
./batch_transfer_optimized.sh --delay 60

# 方案 2: 使用 Xget
python3 transfer.py --use-xget ...

# 方案 3: 等待后重试
sleep 300 && retry_command
```

---

## 决策树

```
需要传输模型？
├─ 是 → 需要立即可用？
│      ├─ 是 → 完整传输（默认）
│      └─ 否 → 指针模式（--skip-lfs-errors）
└─ 否 → 仅文本（--ignore-lfs）

批量传输？
├─ 是 → 有优先级？
│      ├─ 是 → 分阶段策略
│      └─ 否 → 批量脚本
└─ 否 → 单个传输

速度要求？
├─ 快 → --ignore-lfs 或 --use-xget
└─ 慢 → 默认模式
```

---

## 命令速查

```bash
# 完整
python3 transfer.py -s SRC -t TGT

# 文本
python3 transfer.py -s SRC -t TGT --ignore-lfs

# 指针
GIT_LFS_SKIP_SMUDGE=1 python3 transfer.py -s SRC -t TGT --skip-lfs-errors

# 批量文本
./batch_transfer_optimized.sh --ignore-lfs

# 批量指针
GIT_LFS_SKIP_SMUDGE=1 ./batch_transfer_optimized.sh --skip-lfs-errors

# 加速
python3 transfer.py -s SRC -t TGT --use-xget

# 镜像
python3 transfer.py -s SRC -t TGT --mirror
```

---

## 相关文档

- 📖 [STAGED_TRANSFER_GUIDE.md](STAGED_TRANSFER_GUIDE.md) - 详细使用指南
- 📖 [README.md](README.md) - 完整功能说明
- 📖 [BATCH_TRANSFER_GUIDE.md](BATCH_TRANSFER_GUIDE.md) - 批处理指南
- 📖 [QUICKSTART.md](QUICKSTART.md) - 快速开始

---

**最后更新：** December 2025

