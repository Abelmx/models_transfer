# ✅ 实时日志显示修复

## 问题说明

你遇到的问题：GitHub Actions 日志显示卡在这里：

```
ℹ Attempting transfer (attempt 1)
ℹ   Source: https://huggingface.co/internlm/Intern-S1-mini
ℹ   Target: ***/Intern-S1-mini.git

(然后就没有输出了...)
```

**原因分析：**

1. **批处理脚本问题** (`batch_transfer_optimized.sh`)
   - 第 180 行：`eval "$cmd" >> "$LOG_FILE" 2>&1`
   - 所有输出都重定向到日志文件
   - 终端看不到任何实时输出

2. **Python 脚本问题** (`transfer.py`)
   - `run_command()` 使用 `capture_output=True`
   - 等待整个命令执行完才显示输出
   - Git clone 的进度条被缓存，看起来像卡住了

---

## 已修复 ✅

### 修复 1: 批处理脚本实时输出

**修改前：**
```bash
if eval "$cmd" >> "$LOG_FILE" 2>&1; then
```

**修改后：**
```bash
if eval "$cmd" 2>&1 | tee -a "$LOG_FILE"; then
```

**效果：** 输出同时显示在终端和日志文件中

---

### 修复 2: Python 脚本流式输出

**修改前：**
```python
result = subprocess.run(
    cmd,
    capture_output=True,  # 捕获所有输出
    ...
)
```

**修改后：**
```python
result = subprocess.run(
    cmd,
    # 不捕获输出，直接流式显示
    stream_output=True,  # 新参数，默认启用
    ...
)
```

**效果：** Git 命令的输出实时流式显示

---

## 现在你应该看到什么

更新代码后重新运行 workflow，你会看到：

```
ℹ Attempting transfer (attempt 1)
ℹ   Source: https://huggingface.co/internlm/Intern-S1-mini
ℹ   Target: ***/Intern-S1-mini.git

🔧 Executing: python3 transfer.py --source '...' --target '...'

============================================================
📥 Step 1: Cloning source repository from HuggingFace
============================================================

🔧 Executing: git clone https://...

Cloning into '/tmp/hf_transfer_xxxxx/repo'...
remote: Enumerating objects: 123, done.
remote: Counting objects: 100% (123/123), done.
remote: Compressing objects: 100% (45/45), done.
remote: Total 456 (delta 78), reused 123 (delta 45)
Receiving objects: 100% (456/456), 12.34 MiB | 5.67 MiB/s, done.
Resolving deltas: 100% (78/78), done.

✅ Source repository cloned successfully

============================================================
📦 Step 2: Handling Git LFS files
============================================================

🔧 Executing: git lfs fetch --all

...（实时显示进度）
```

---

## 立即应用修复

### 步骤 1: 取消当前运行（如果还在运行）

访问：`https://github.com/Abelmx/models_transfer/actions`

点击正在运行的 workflow → 点击右上角 `Cancel workflow`

### 步骤 2: 确保代码最新

代码已自动推送到 GitHub（提交 `c57cb27`）

### 步骤 3: 重新运行

1. 访问 Actions 页面
2. 点击 `Batch Model Transfer`
3. 点击 `Run workflow`
4. 使用相同参数运行

### 步骤 4: 观察日志

现在你应该能看到：

✅ **实时克隆进度：**
```
Receiving objects: 45% (2056/4567), 234.56 MiB | 12.34 MiB/s
```

✅ **每个步骤的详细输出：**
```
📥 Step 1: Cloning source repository
📦 Step 2: Handling Git LFS files
🔄 Step 3: Changing remote
📤 Step 4: Pushing to target platform
```

✅ **Git 命令的实时反馈：**
```
🔧 Executing: git clone ...
🔧 Executing: git lfs fetch --all
🔧 Executing: git push ...
```

---

## 预期传输时间

基于 Intern-S1-mini（约 10 GB）：

| 阶段 | 时间 | 显示内容 |
|------|------|---------|
| **Clone** | 5-15 分钟 | 实时进度条 |
| **LFS fetch** | 10-20 分钟 | 实时下载速度 |
| **Push** | 10-20 分钟 | 实时上传进度 |
| **总计** | **25-55 分钟** | 全程可见 |

---

## 进度监控技巧

### 1. 搜索关键字

在 GitHub Actions 日志中搜索：

- `Receiving objects` - 克隆进度
- `Downloading` - LFS 下载进度
- `Uploading` - LFS 上传进度
- `Writing objects` - 推送进度

### 2. 查看百分比

留意这些百分比指示器：
```
Receiving objects: 67% (3056/4567)
Downloading LFS objects: 45% (234/520)
Writing objects: 89% (4056/4567)
```

### 3. 关注速度指标

```
12.34 MiB | 5.67 MiB/s  ← 当前下载速度
```

如果速度突然降到 0，可能：
- 网络波动（等待几分钟）
- 遇到大文件（正常，会继续）
- 真的卡住了（等待 5 分钟后考虑重启）

---

## 故障排查

### 问题 1: 仍然看不到实时输出

**检查：**
1. 确认代码已更新（提交 `c57cb27`）
2. 刷新 GitHub Actions 页面
3. 查看是否使用了旧的 workflow

**解决：**
```bash
# 本地确认
cd /home/maoxin/transfer
git pull origin main
git log --oneline -1
# 应该显示：c57cb27 Enable real-time log streaming
```

---

### 问题 2: 日志显示 "Executing" 后就停了

**可能原因：**
- Git clone 正在进行，但 Git 没有输出进度
- 网络连接问题
- HuggingFace 服务器响应慢

**检查：**
1. 等待 5-10 分钟（大文件需要时间）
2. 查看 GitHub Actions 的 runner 状态
3. 检查是否有 Xget 加速（你的配置中是 false）

**建议：**
启用 Xget 加速可以显著提高速度：
```
Use Xget acceleration: true
```

---

### 问题 3: 进度停在某个百分比

**例如：**
```
Receiving objects: 67% (3056/4567)
(停在这里 10 分钟...)
```

**原因：**
- 正在下载一个非常大的 LFS 文件
- 网络暂时中断

**处理：**
1. 耐心等待（大文件可能需要 10-30 分钟）
2. 如果超过 30 分钟没有变化，考虑取消重试
3. 检查日志文件（Artifacts）中的错误信息

---

## 技术细节

### 修改的文件

1. **`batch_transfer_optimized.sh`**（第 180 行）
   ```bash
   # 修改前
   if eval "$cmd" >> "$LOG_FILE" 2>&1; then
   
   # 修改后
   if eval "$cmd" 2>&1 | tee -a "$LOG_FILE"; then
   ```

2. **`transfer.py`**（`run_command` 方法）
   ```python
   # 添加了 stream_output 参数
   def run_command(self, cmd, ..., stream_output=True):
       if stream_output:
           # 实时流式输出
           subprocess.run(cmd, ...)
       else:
           # 捕获输出（用于解析结果）
           subprocess.run(cmd, capture_output=True, ...)
   ```

### 为什么之前看起来卡住了？

**批处理脚本层面：**
```
用户终端 ← ❌ 看不到
            ↑
    batch_transfer.sh
            ↓
       日志文件 ← ✅ 所有输出都在这里
```

**Python 脚本层面：**
```
git clone 开始 → 下载 30GB 数据 → 完成后才输出
                    ↑
               看起来卡住了
              （实际在下载）
```

### 修复后的流程

```
git clone → 每秒输出进度 → 用户终端 + 日志文件
            ↑
    实时可见，不会卡住
```

---

## 验证修复成功

运行 workflow 后，你应该看到：

✅ **克隆阶段**
```
🔧 Executing: git clone ...
Cloning into '/tmp/...'
remote: Enumerating objects: ...
Receiving objects: 23% (1234/5678), 123.45 MiB | 6.78 MiB/s
```

✅ **LFS 阶段**
```
🔧 Executing: git lfs fetch --all
Downloading LFS objects: 12% (67/560)
Git LFS: (234 of 560 files) 12.34 GB / 45.67 GB, 6.78 MB/s
```

✅ **推送阶段**
```
🔧 Executing: git push ...
Writing objects: 45% (2345/5234)
Delta compression using up to 4 threads
```

---

## 相关文档

- [GITHUB_ACTIONS_GUIDE.md](GITHUB_ACTIONS_GUIDE.md) - 完整使用指南
- [QUICK_START_GITHUB_ACTIONS.md](QUICK_START_GITHUB_ACTIONS.md) - 快速开始
- [DISK_SPACE_QUICK_FIX.md](DISK_SPACE_QUICK_FIX.md) - 磁盘空间解决方案

---

## 总结

**问题：** 日志看起来卡住了  
**原因：** 输出被重定向，没有实时显示  
**修复：** 启用实时流式输出  
**效果：** 现在可以看到 git 命令的实时进度  

**立即操作：**
1. 取消当前运行
2. 重新运行 workflow
3. 观察实时输出

**最后更新：** December 2025

