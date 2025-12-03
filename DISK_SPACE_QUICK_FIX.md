# 💾 磁盘空间问题 - 快速修复

## 问题

```
❌ error: no space left on device
❌ fatal: cannot copy ... to ...: No space left on device
```

---

## ✅ 已自动修复！

**Workflow 已更新，包含自动磁盘清理步骤。**

### 效果

| 项目 | 清理前 | 清理后 |
|------|-------|--------|
| 可用空间 | ~10 GB | **~35 GB** ✅ |
| 可传输模型大小 | < 10 GB | < 35 GB |
| Intern-S1 (30GB) | ❌ 不可行 | ✅ **可以传输** |

---

## 🚀 立即使用

### 步骤 1: 确保代码最新

```bash
cd /home/maoxin/transfer
git pull origin main
```

### 步骤 2: 推送到 GitHub（如果本地有修改）

```bash
git push origin main
```

### 步骤 3: 运行 Workflow

访问：`https://github.com/Abelmx/models_transfer/actions`

点击 `Batch Model Transfer` → `Run workflow`

### 步骤 4: 验证清理成功

在 Actions 日志中查看：

```
============================================
After cleanup:
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        84G   12G   72G  15% /
                           ^^^^
                         关注这个数字
                       应该 > 30 GB
============================================
```

---

## 📊 清理细节

Workflow 自动删除以下不需要的软件：

| 软件 | 释放空间 |
|------|---------|
| .NET SDK | ~2.8 GB |
| Android SDK | ~11 GB |
| GHC (Haskell) | ~2.5 GB |
| CodeQL | ~5 GB |
| Boost | ~1 GB |
| **总计** | **~20-30 GB** |

---

## 🔧 仍然空间不足？

### 方案 A: 分批传输（推荐）

**如果有多个大模型（每个 > 20 GB）：**

创建多个配置文件：

**`batch_config_part1.txt`**:
```
internlm/Intern-S1
```

**`batch_config_part2.txt`**:
```
internlm/Intern-S1-mini
```

分两次运行 workflow。

---

### 方案 B: 指针模式（高级）

**只传输 Git 结构，不传输大文件：**

1. 在 GitHub Secrets 添加：
   - Name: `GIT_LFS_SKIP_SMUDGE`
   - Value: `1`

2. 运行时设置：
   - `Skip LFS push errors`: `true`

**效果：** 空间需求从 30GB 降至 50MB

---

### 方案 C: 仅文本传输

**快速建立仓库结构，稍后传输权重：**

运行时设置：
- `Ignore LFS files`: `true`

**效果：** 
- 阶段 1：5 分钟完成（仅文本）
- 阶段 2：稍后完整传输

---

## 📖 详细文档

不同模型大小的最佳方案：

| 模型大小 | 推荐方案 | 文档链接 |
|---------|---------|---------|
| < 20 GB | 自动清理（无需操作） | - |
| 20-40 GB | 自动清理 | - |
| > 40 GB | 清理 + 分批 | [详细指南](GITHUB_ACTIONS_DISK_SPACE.md) |
| > 50 GB | 分批或指针模式 | [详细指南](GITHUB_ACTIONS_DISK_SPACE.md) |

---

## ✅ 检查清单

确认以下项目：

- [ ] ✅ 本地代码已更新（`git pull`）
- [ ] ✅ 代码已推送到 GitHub（`git push`）
- [ ] ✅ Workflow 文件包含 "Maximize disk space" 步骤
- [ ] ✅ 运行 workflow
- [ ] ✅ 查看日志验证清理成功（可用空间 > 30 GB）
- [ ] ✅ 传输开始

---

## 🎯 快速决策树

```
遇到 "No space left on device"？
    ↓
代码是否最新？
├─ 否 → git pull && git push
└─ 是 ↓
       ↓
查看日志 "After cleanup"
    ↓
可用空间 > 30 GB？
├─ 是 → 应该可以正常传输，检查其他问题
└─ 否 ↓
       ↓
模型 < 40 GB？
├─ 是 → 使用分批传输（方案 A）
└─ 否 → 使用指针模式（方案 B）或分批传输
```

---

## 💡 小提示

1. **首次运行需要 5-10 分钟清理**
   - 清理过程会显示进度
   - 耐心等待，只需要做一次

2. **清理后的 runner 可以重复使用**
   - GitHub 可能会复用同一个 runner
   - 下次运行可能更快

3. **分批传输最保险**
   - 每次只传输一个大模型
   - 避免意外情况

4. **监控磁盘使用**
   - 在日志中搜索 "disk space"
   - 查看传输前后的空间变化

---

## 🆘 仍然无法解决？

1. 下载 Actions 日志（Artifacts）
2. 查找 "disk space" 相关信息
3. 检查实际可用空间
4. 查看详细文档：[GITHUB_ACTIONS_DISK_SPACE.md](GITHUB_ACTIONS_DISK_SPACE.md)
5. 在 GitHub Issues 提问（附上日志）

---

## 📞 相关链接

- 📖 [完整磁盘空间指南](GITHUB_ACTIONS_DISK_SPACE.md)
- 🚀 [GitHub Actions 快速启动](QUICK_START_GITHUB_ACTIONS.md)
- 📚 [GitHub Actions 完整指南](GITHUB_ACTIONS_GUIDE.md)

---

**总结：Workflow 已自动配置磁盘清理，更新代码后重新运行即可！** ✅

**最后更新:** December 2025

