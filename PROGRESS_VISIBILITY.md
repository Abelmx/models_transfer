# 🔍 进度显示说明

## 常见"卡住"现象

### 现象 1: Clone 后长时间无输出

**日志显示：**
```
Filtering content: 100% (2/2), 394.09 MiB | 13.10 MiB/s
Filtering content: 100% (2/2), 394.09 MiB | 13.06 MiB/s, done.
Fetching all references...
2 objects found, done.
Locking support detected on remote "origin"...

(然后没有输出...)
```

**实际情况：** ✅ **正在推送 LFS 文件，没有卡住！**

**原因：**
1. Git LFS push 正在上传 394 MB 的文件
2. 进度可能需要几秒才开始显示
3. 大文件上传需要时间

**等待时间：**
- 394 MB @ 5 MB/s = 约 80 秒
- 394 MB @ 10 MB/s = 约 40 秒

---

## 如何判断是否正常

### ✅ 正常进行中

**特征：**
1. 看到 "Locking support detected..."
2. 等待 1-2 分钟后会看到进度
3. GitHub Actions 任务状态是运行中（蓝色圆圈）

**应该做：**
- 耐心等待
- 不要取消任务
- 等待进度条出现

---

### ❌ 真的卡住了

**特征：**
1. 超过 10 分钟没有任何输出
2. 没有进度更新
3. CPU 使用率为 0

**应该做：**
- 取消并重试
- 检查网络连接
- 查看是否有错误消息

---

## 完整的传输阶段

### 阶段 1: Clone（1-5 分钟）

```
📥 Step 1/4: Cloning source repository...
→ git clone https://...

Cloning into '/tmp/...'
remote: Enumerating objects: 123, done.
remote: Counting objects: 100% (123/123), done.
Receiving objects: 100% (123/123), 12.34 MiB | 5.67 MiB/s
Filtering content: 100% (2/2), 394.09 MiB | 13.10 MiB/s ← 下载 LFS
```

**什么时候担心：** 超过 10 分钟没有进度变化

---

### 阶段 2: Fetch LFS（5-20 分钟）

```
📦 Step 2/4: Fetching Git LFS files...
Downloading LFS objects (this may take a while)...
→ git lfs fetch --all

Downloading LFS objects: 23% (234/1000)
Git LFS: (234 of 1000 files) 12.34 GB / 45.67 GB, 5.67 MB/s
```

**什么时候担心：** 超过 30 分钟没有进度变化

---

### 阶段 3: Change Remote（< 1 秒）

```
🔄 Step 3/4: Changing remote to target...
→ git remote remove origin
→ git remote add origin https://...
```

**什么时候担心：** 超过 5 秒（这个很快）

---

### 阶段 4: Push（5-30 分钟）⚠️

```
📤 Step 4/4: Pushing to target repository...
Pushing LFS objects (this may take a while for large files)...
→ git lfs push origin --all

Locking support detected on remote "origin"... ← 你看到这里

(等待 1-2 分钟后会显示进度)

Uploading LFS objects:  12% (67/560)          ← 应该会出现这个
Git LFS: (234 of 560 files) 12.34 GB / 45.67 GB, 6.78 MB/s

Uploading LFS objects: 100% (560/560), 45.67 GB | 6.78 MB/s, done.

Pushing branch 'main' to target...
→ git push -u origin main --force

Writing objects: 100% (123/123), 12.34 MiB | 5.67 MiB/s
```

**什么时候担心：** 
- 看到 "Locking support..." 后超过 5 分钟没有进度
- 进度停在某个百分比超过 30 分钟

---

## 预估时间表

基于不同模型大小：

| 模型大小 | Clone | LFS Fetch | Push | 总计 |
|---------|-------|-----------|------|------|
| 小模型（< 1 GB） | 1-2 分钟 | 2-5 分钟 | 2-5 分钟 | 5-12 分钟 |
| 中等模型（1-10 GB） | 2-5 分钟 | 5-15 分钟 | 5-15 分钟 | 12-35 分钟 |
| 大模型（10-30 GB） | 5-15 分钟 | 15-45 分钟 | 15-45 分钟 | 35-105 分钟 |
| 超大模型（> 30 GB） | 15-30 分钟 | 45-120 分钟 | 45-120 分钟 | 105-270 分钟 |

**InternVL3.5-2B（约 4 GB）：** 预计 15-30 分钟

---

## 实时监控技巧

### 技巧 1: 搜索关键字

在 GitHub Actions 日志中搜索：

- `Receiving objects` - Clone 进度
- `Filtering content` - LFS 下载进度
- `Downloading LFS` - LFS Fetch 进度
- `Uploading LFS` - LFS Push 进度
- `Writing objects` - Git Push 进度

---

### 技巧 2: 查看百分比

```
Uploading LFS objects: 67% (345/520)
                       ^^^
                    关注这个数字
```

如果百分比在增加 → ✅ 正常进行中

---

### 技巧 3: 查看速度

```
12.34 GB | 6.78 MB/s
           ^^^^^^^^^^^
        关注传输速度
```

如果速度 > 0 → ✅ 正常传输中

---

### 技巧 4: 查看 GitHub Actions 状态

在 Actions 页面：
- 🔵 蓝色圆圈转动 = 运行中
- ✅ 绿色勾号 = 完成
- ❌ 红色 X = 失败
- 🟡 黄色 = 排队中

---

## 当前问题的诊断

### 你的日志

```
Filtering content: 100% (2/2), 394.09 MiB | 13.10 MiB/s, done.
Fetching all references...
2 objects found, done.
Locking support detected on remote "origin"...
```

**诊断：**
1. ✅ Clone 完成（394 MB 已下载）
2. ✅ 开始 LFS push（"Locking support..." 是 push 开始标志）
3. ⏳ **正在上传 394 MB 到目标仓库**

**预计时间：**
- 如果速度 5 MB/s：约 80 秒
- 如果速度 10 MB/s：约 40 秒

**建议：**
1. 再等待 2-3 分钟
2. 应该会看到 "Uploading LFS objects..." 进度
3. 如果 5 分钟后仍无输出，考虑重试

---

## 代码已修复 ✅

**更新后的代码会显示：**

```
📤 Step 4/4: Pushing to target repository...
Pushing LFS objects (this may take a while for large files)...
→ git lfs push origin --all

Locking support detected on remote "origin"...
Uploading LFS objects:  12% (1/8)              ← 新增：实时进度
Uploading LFS objects:  25% (2/8)
Uploading LFS objects:  37% (3/8)
...
Uploading LFS objects: 100% (8/8), 394.09 MiB | 8.23 MB/s, done.

Pushing branch 'main' to target...
→ git push -u origin main --force
Writing objects: 100% (10/10), 1.23 KiB | 1.23 MiB/s, done.

✅ Transfer completed successfully!
```

---

## 故障排查清单

### 如果传输看起来卡住了

- [ ] 等待至少 5 分钟
- [ ] 检查是否有进度百分比更新
- [ ] 查看 GitHub Actions 状态（是否仍在运行）
- [ ] 搜索日志中的错误信息
- [ ] 查看磁盘空间是否充足
- [ ] 检查网络连接

### 如果确实卡住了

1. **取消当前运行**
   - 点击 "Cancel workflow"

2. **检查问题**
   - 下载日志（Artifacts）
   - 查找错误消息

3. **重新运行**
   - 使用相同的输入
   - 观察是否在同一位置卡住

---

## 常见错误信息

### 错误 1: 网络超时

```
error: RPC failed; HTTP 504
fatal: the remote end hung up unexpectedly
```

**解决：** 重试，可能是临时网络问题

---

### 错误 2: 磁盘空间不足

```
error: no space left on device
```

**解决：** Workflow 已包含磁盘清理，通常不会遇到

---

### 错误 3: 认证失败

```
error: failed to push some refs
remote: You are not allowed to push code to this project.
```

**解决：** 检查 `TARGET_TOKEN` 权限

---

## 最佳实践

### 1. 耐心等待

**大文件传输需要时间，这是正常的！**

- 小文件（< 100 MB）：1-2 分钟
- 中等文件（100 MB - 1 GB）：5-10 分钟
- 大文件（1-10 GB）：10-30 分钟
- 超大文件（> 10 GB）：30 分钟+

---

### 2. 分批传输

如果有多个大模型：

```
# 第一次运行（单个）
https://huggingface.co/model1|https://target.com/model1.git

# 第二次运行（单个）
https://huggingface.co/model2|https://target.com/model2.git
```

---

### 3. 使用完整版（更快）

如果需要更快速度，使用完整版的 Xget 加速：

```bash
./batch_transfer_optimized.sh --use-xget --config models.txt
```

速度提升 3-15 倍！

---

## 总结

**"Locking support detected..." 不是错误！**

这是 Git LFS push 的正常输出，表示：
1. ✅ 目标仓库支持 LFS
2. ✅ 正在上传 LFS 文件
3. ⏳ 需要等待上传完成

**耐心等待，传输正在进行中！** 🚀

---

## 相关文档

- [SIMPLE_TRANSFER_GUIDE.md](SIMPLE_TRANSFER_GUIDE.md) - 使用指南
- [REALTIME_LOGGING_FIX.md](REALTIME_LOGGING_FIX.md) - 日志显示修复
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 完整故障排查

**最后更新：** December 2025

