# GitHub Actions 磁盘空间问题解决方案

## 问题说明

**错误信息：**
```
error: no space left on device
fatal: cannot copy ... to ...: No space left on device
```

**原因分析：**

GitHub Actions 免费 runner 的磁盘空间限制：

| 项目 | 大小 |
|------|------|
| 总磁盘空间 | 14 GB |
| 系统占用 | ~4-5 GB |
| **实际可用** | **~9-10 GB** |

对于大型模型（如 Intern-S1 约 30GB），即使压缩也会超出空间限制。

---

## 解决方案对比

| 方案 | 额外空间 | 难度 | 推荐指数 | 适用场景 |
|------|---------|------|---------|---------|
| **方案 1: 清理磁盘** | +20-30 GB | ⭐ 简单 | ⭐⭐⭐⭐⭐ | 所有场景 |
| **方案 2: 分批传输** | 不增加 | ⭐ 简单 | ⭐⭐⭐⭐ | 多个大模型 |
| **方案 3: 指针模式** | 节省 90% | ⭐⭐ 中等 | ⭐⭐⭐ | 共享 LFS 存储 |
| **方案 4: 仅文本传输** | 节省 99% | ⭐ 简单 | ⭐⭐⭐ | 分阶段部署 |
| **方案 5: 自托管 Runner** | 无限制 | ⭐⭐⭐⭐⭐ 复杂 | ⭐⭐ | 企业用户 |

---

## 方案 1: 清理 Runner 磁盘空间（推荐）⭐

### 自动清理（已配置）

Workflow 已自动添加清理步骤，会删除以下不需要的软件：

- .NET SDK (~2.8 GB)
- Android SDK (~11 GB)
- GHC (Haskell) (~2.5 GB)
- CodeQL (~5 GB)
- Boost (~1 GB)

**效果：释放约 20-30 GB 空间，总可用空间达到 30-35 GB**

### 验证空间是否足够

在 Actions 日志中查看：

```
============================================
Initial disk space:
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        84G   12G   72G  15% /

After cleanup:
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        84G   12G   72G  15% /
============================================
```

如果 `Avail` 列显示 > 35 GB，说明清理成功。

---

## 方案 2: 分批传输（配合方案 1）

### 适用场景

- 有多个大型模型（每个 > 20 GB）
- 磁盘清理后仍然空间不足
- 想分散传输时间

### 操作步骤

**步骤 1: 拆分配置文件**

创建多个配置文件：

**`batch_config_part1.txt`**（第一批）:
```
internlm/Intern-S1
```

**`batch_config_part2.txt`**（第二批）:
```
internlm/Intern-S1-mini
```

**步骤 2: 分别运行**

1. 第一次运行：使用 `batch_config_part1.txt`
   - 修改 workflow 或手动编辑
   - 运行完成后再运行第二批

2. 第二次运行：使用 `batch_config_part2.txt`

**优点：**
- 确保单个模型有足够空间
- 失败后容易重试
- 可以分散在不同时间执行

---

## 方案 3: 指针模式（GIT_LFS_SKIP_SMUDGE=1）

### 工作原理

只下载 Git 结构和 LFS 指针文件，不下载实际的大文件。

**空间节省：** 
- 原始模型：30 GB
- 指针模式：约 50 MB
- **节省 99%+**

### 配置步骤

**步骤 1: 在 GitHub Secrets 中添加**

添加新的 Secret：
- Name: `GIT_LFS_SKIP_SMUDGE`
- Value: `1`

**步骤 2: 修改 workflow**

在 `.github/workflows/batch_transfer.yml` 的 `Configure environment` 步骤中添加：

```yaml
GIT_LFS_SKIP_SMUDGE=1
```

**步骤 3: 运行时启用**

在运行 workflow 时，设置：
- `Skip LFS push errors`: `true`

### 注意事项

⚠️ **重要限制：**
- 目标仓库中只有 LFS 指针，没有实际文件
- 克隆目标仓库时需要配置 LFS 存储
- 适用于源和目标共享 LFS 存储的场景

**适用场景：**
- 只需要同步 Git 结构和版本历史
- 目标平台稍后会从其他渠道获取 LFS 对象
- 多个 Git 远程共享同一 LFS 存储

---

## 方案 4: 仅文本传输（--ignore-lfs）

### 工作原理

完全忽略 LFS 文件，只传输代码、配置、文档等文本文件。

**空间节省：**
- 原始模型：30 GB
- 仅文本：约 10 MB
- **节省 99.9%**

### 配置步骤

运行 workflow 时，设置：
- `Ignore LFS files`: `true`

### 使用场景

**阶段 1: 快速建立仓库结构**
```
Ignore LFS files: true
Delay: 30
```
**效果：** 5-10 分钟内完成所有仓库的文本文件传输

**阶段 2: 传输模型权重**（可选）
```
Ignore LFS files: false
Use Xget acceleration: true
Delay: 120
```
**效果：** 完整传输（1-2 小时/模型）

### 优点

- ✅ 极快速度（每个仓库 < 1 分钟）
- ✅ 几乎不消耗磁盘空间
- ✅ 团队可以立即查看代码和文档
- ✅ 完美的分阶段策略

### 缺点

- ❌ 目标仓库缺少模型权重文件
- ❌ 无法直接加载模型

---

## 方案 5: 自托管 Runner（企业方案）

### 适用场景

- 企业内部使用
- 有自己的服务器
- 需要大磁盘空间（> 100 GB）
- 传输非常大的模型（> 50 GB）

### 配置步骤

**步骤 1: 准备服务器**

要求：
- Linux/macOS/Windows
- 磁盘空间 > 100 GB
- 网络连接良好
- Docker（可选）

**步骤 2: 注册 Runner**

1. 访问：`https://github.com/YOUR_USERNAME/models_transfer/settings/actions/runners`
2. 点击 `New self-hosted runner`
3. 按照指引在服务器上安装并启动 runner

**步骤 3: 修改 workflow**

```yaml
jobs:
  transfer:
    runs-on: self-hosted  # 改为使用自托管 runner
    # runs-on: ubuntu-latest
```

### 优点

- ✅ 磁盘空间无限制
- ✅ 可以自定义配置
- ✅ 更快的网络（如果服务器网络好）
- ✅ 完全控制

### 缺点

- ❌ 需要维护服务器
- ❌ 安全责任自负
- ❌ 配置复杂

---

## 推荐配置（分情况）

### 情况 1: 单个大模型（20-40 GB）

**推荐：方案 1（磁盘清理）**

```yaml
# workflow 已自动配置清理步骤
# 直接运行即可
Use Xget acceleration: true
Delay: 60
Max retries: 3
```

**预期：**
- 清理后可用空间：~35 GB
- Intern-S1（30 GB）可以正常传输

---

### 情况 2: 多个大模型（总计 > 50 GB）

**推荐：方案 1 + 方案 2（清理 + 分批）**

**batch_config_part1.txt**:
```
internlm/Intern-S1
```

**batch_config_part2.txt**:
```
internlm/Intern-S1-mini
other-org/other-model
```

分两次运行 workflow，每次使用不同的配置文件。

---

### 情况 3: 快速部署 + 后期同步

**推荐：方案 1 + 方案 4（清理 + 分阶段）**

**阶段 1（5-10 分钟）**:
```
Ignore LFS files: true
Delay: 30
```

**阶段 2（1-2 天后）**:
```
Ignore LFS files: false
Use Xget acceleration: true
Delay: 120
```

---

### 情况 4: 超大模型（> 50 GB）

**推荐：方案 5（自托管 Runner）**

或者使用指针模式（方案 3）+ 手动 LFS 同步。

---

## 故障排查

### 问题 1: 清理后仍然空间不足

**检查清理是否成功：**

在 Actions 日志中搜索 "After cleanup"，查看可用空间（Avail 列）。

**如果 < 30 GB：**

1. 检查 workflow 清理步骤是否执行
2. 尝试添加更多清理命令：

```yaml
- name: Maximize disk space
  run: |
    # 添加这些额外清理
    sudo docker system prune -a -f
    sudo rm -rf /usr/local/graalvm/
    sudo rm -rf /usr/local/.ghcup/
    sudo rm -rf /usr/local/share/powershell
```

---

### 问题 2: 传输过程中空间耗尽

**原因：** 模型实际大小超出预期

**解决：**

1. **使用指针模式**
   ```
   Skip LFS push errors: true
   ```
   在 Secrets 中设置 `GIT_LFS_SKIP_SMUDGE=1`

2. **分批传输**
   - 每次只传输一个模型
   - 确保单个模型 < 30 GB

---

### 问题 3: Git clone 失败

**错误：**
```
fatal: the remote end hung up unexpectedly
```

**可能原因：**
- 网络超时
- 磁盘空间不足
- LFS 下载失败

**解决：**

1. 检查磁盘空间（见问题 1）
2. 增加重试次数：`Max retries: 5`
3. 增加延迟：`Delay: 180`

---

## 监控磁盘使用

### 查看实时磁盘使用

在 Actions 日志中搜索：

```
Available disk space before transfer:
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        84G   XX    YYG   ZZ% /
```

关键指标：
- `Used`: 已使用空间
- `Avail`: 可用空间（应该 > 模型大小）
- `Use%`: 使用百分比（应该 < 80%）

---

## 成本对比

### GitHub Actions 免费版

| 方案 | 单次成本 | 月度额度 | 可传输模型数 |
|------|---------|---------|------------|
| 磁盘清理 | 免费 | 2000 分钟 | ~44 个（30GB/个） |
| 分批传输 | 免费 | 2000 分钟 | 同上 |
| 指针模式 | 免费 | 2000 分钟 | ~400 个 |
| 仅文本 | 免费 | 2000 分钟 | ~1000 个 |

### 自托管 Runner

| 配置 | 月度成本 | 磁盘空间 | 传输能力 |
|------|---------|---------|---------|
| VPS（基础） | $5-10/月 | 50-100 GB | 无限制 |
| VPS（高配） | $20-50/月 | 200-500 GB | 高速传输 |
| 闲置服务器 | 免费 | 1TB+ | 取决于网络 |

---

## 最佳实践

### 1. 始终启用磁盘清理

Workflow 已自动配置，无需额外操作。

### 2. 预估模型大小

在传输前检查模型大小：
```bash
# 访问 HuggingFace 模型页面
https://huggingface.co/internlm/Intern-S1

# 查看 "Files and versions" 标签
```

### 3. 选择合适的方案

| 模型大小 | 推荐方案 |
|---------|---------|
| < 20 GB | 方案 1（磁盘清理） |
| 20-40 GB | 方案 1 |
| > 40 GB | 方案 1 + 方案 2（分批） |
| > 50 GB | 方案 5（自托管）或方案 3（指针） |

### 4. 监控日志

每次运行后检查：
- 磁盘使用情况
- 传输是否完整
- 有无错误信息

### 5. 增量更新

对于已经传输过的模型：
- 使用 `--mirror` 模式增量同步
- 只传输更新的部分
- 节省时间和空间

---

## 相关文档

- [GITHUB_ACTIONS_GUIDE.md](GITHUB_ACTIONS_GUIDE.md) - 完整配置指南
- [QUICK_START_GITHUB_ACTIONS.md](QUICK_START_GITHUB_ACTIONS.md) - 快速开始
- [STAGED_TRANSFER_GUIDE.md](STAGED_TRANSFER_GUIDE.md) - 分阶段传输策略

---

## 总结

**最简单有效的方案：**

1. ✅ 使用已配置的磁盘清理（自动，释放 20-30 GB）
2. ✅ 单次传输单个大模型（< 40 GB）
3. ✅ 多个模型使用分批传输

**对于 Intern-S1（30 GB）：**
- 磁盘清理后可用空间：~35 GB
- 完全足够传输！

**立即行动：**
1. 确保 workflow 已更新（包含磁盘清理步骤）
2. 推送到 GitHub
3. 运行 workflow
4. 查看日志验证磁盘空间

**最后更新:** December 2025

