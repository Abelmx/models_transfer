# 🚀 GitHub Actions 快速启动指南

**5 分钟配置，云端高速传输模型！**

---

## ⚡ 一键配置

### 第 1 步：配置 GitHub Secrets（2 分钟）

访问你的仓库 Secrets 设置：
```
https://github.com/Abelmx/models_transfer/settings/secrets/actions
```

点击 `New repository secret`，添加以下 3 个密钥：

| Name | Value | 示例 |
|------|-------|------|
| **TARGET_BASE_URL** | 目标仓库基础 URL | `https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin` |
| **TARGET_USERNAME** | 目标平台用户名 | `maoxin` |
| **TARGET_TOKEN** | 目标平台 Token | `glpat-xxxxxxxxxxxxxxxx` |

> ⚠️ **重要**: 不要包含 `username:token@` 前缀，只填写 Token 本身！

---

### 第 2 步：编辑模型列表（1 分钟）

编辑 `batch_config.txt` 文件：

```
# 添加你要传输的模型（每行一个）
internlm/Intern-S1
internlm/Intern-S1-mini
```

保存并推送到 GitHub：
```bash
git add batch_config.txt
git commit -m "Update model list"
git push origin main
```

---

### 第 3 步：运行传输（1 分钟）

1. 访问 Actions 页面：
   ```
   https://github.com/Abelmx/models_transfer/actions
   ```

2. 点击左侧 `Batch Model Transfer`

3. 点击右侧 `Run workflow` 按钮

4. 配置参数（推荐默认值）：
   - ✅ Use Xget acceleration: `true`
   - Delay between models: `60`
   - Max retry attempts: `3`

5. 点击绿色 `Run workflow` 按钮

---

## 📊 监控进度

### 实时查看

1. 在 Actions 页面，点击运行中的 workflow
2. 点击 `transfer` job
3. 查看实时日志输出

### 预计时间

基于 Intern-S1（约 30GB）：

| 模型 | 预计时间 | 说明 |
|------|---------|------|
| Intern-S1 | 45-60 分钟 | 大模型，约 30GB |
| Intern-S1-mini | 15-30 分钟 | 小模型，约 10GB |

> 💡 **提示**: GitHub Actions 使用高速网络，比本地快 10-100 倍！

---

## ✅ 传输完成

### 检查结果

1. 等待 workflow 显示绿色勾号 ✅
2. 检查目标平台：
   ```
   https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1
   https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1-mini
   ```

### 下载日志

1. 滚动到 workflow 页面底部
2. 找到 `Artifacts` 区域
3. 下载 `transfer-logs-xxx.zip`
4. 解压查看详细日志

---

## 🔧 常见问题

### Q1: Secrets 设置错误？

**症状**: Workflow 失败，提示 "No target URL specified"

**解决**:
1. 检查 Secrets 名称拼写：`TARGET_BASE_URL`（全大写）
2. 确保 `TARGET_BASE_URL` 不包含 `username:token@`
3. 重新运行 workflow

---

### Q2: Token 权限不足？

**症状**: 推送失败，提示 "Authentication failed"

**解决**:
1. 在目标平台重新生成 Token
2. 确保 Token 有 `write_repository` 权限
3. 更新 GitHub Secret 中的 `TARGET_TOKEN`

---

### Q3: 传输速度慢？

**症状**: 单个模型超过 2 小时

**解决**:
1. 确保启用了 `Use Xget acceleration: true`
2. 检查目标平台网络状况
3. 尝试分批传输（减少并发）

---

### Q4: HTTP 429 速率限制？

**症状**: 提示 "Too Many Requests"

**解决**:
1. 增加 `Delay between models` 到 120-300 秒
2. 减少每次传输的模型数量
3. 等待几小时后重试

---

## 🎯 优化建议

### 大批量传输

如果有 10+ 个模型：

1. **分批传输**
   ```
   # batch_config_part1.txt
   internlm/Intern-S1
   
   # batch_config_part2.txt
   internlm/Intern-S1-mini
   ```

2. **增加延迟**
   - Delay between models: `180`（3 分钟）

3. **分时段执行**
   - 高峰期：只传输小模型
   - 低峰期：传输大模型

---

### 分阶段策略

**阶段 1: 快速建立仓库结构（5 分钟）**
- Ignore LFS files: `true`
- Delay: `30`

**阶段 2: 传输模型权重（1-2 小时）**
- Ignore LFS files: `false`
- Delay: `120`
- Max retries: `5`

---

## 📖 完整文档

- [GITHUB_ACTIONS_GUIDE.md](GITHUB_ACTIONS_GUIDE.md) - 完整配置指南
- [SECURITY_WARNING.md](SECURITY_WARNING.md) - 安全最佳实践
- [BATCH_TRANSFER_GUIDE.md](BATCH_TRANSFER_GUIDE.md) - 批处理详细说明

---

## 🆘 需要帮助？

1. 查看 [GITHUB_ACTIONS_GUIDE.md](GITHUB_ACTIONS_GUIDE.md) 完整文档
2. 检查 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 故障排查
3. 下载并查看 Artifacts 中的详细日志
4. 在 GitHub Issues 提问（不要包含 Token！）

---

## ✨ 成功案例

**用户 A**: 本地 100KB/s → GitHub Actions 10MB/s，**快了 100 倍**！

**用户 B**: 6 个大模型批量传输，本地需要 2 天 → GitHub Actions 6 小时完成！

**用户 C**: 使用分阶段策略，5 分钟建立 50 个仓库结构，后台慢慢同步权重文件。

---

**开始使用 GitHub Actions，告别本地网络限制！** 🚀

**最后更新:** December 2025

