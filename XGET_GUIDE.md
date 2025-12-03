# Xget Acceleration Guide

## What is Xget?

[Xget](https://github.com/xixu-me/Xget) is an ultra-high-performance, secure, all-in-one acceleration engine for developer resources. It significantly outperforms traditional solutions by delivering unified, efficient acceleration across:

- 🚀 Code repositories (GitHub, GitLab, Bitbucket)
- 🤖 Model and dataset hubs (HuggingFace, ModelScope)
- 📦 Package registries (npm, PyPI, Maven)
- 🐳 Container registries (Docker Hub, ghcr.io)
- 🧠 AI inference providers

## Why Use Xget with This Tool?

When transferring models from HuggingFace, download speed is often the bottleneck. Xget solves this by:

- **3-10x Faster Downloads**: Leveraging global CDN edge network
- **Parallel Chunk Downloads**: Multiple simultaneous connections
- **Automatic Failover**: Smart routing and retry mechanisms
- **Zero Configuration**: Works out of the box with `--use-xget` flag

## How It Works

Xget acts as a proxy/accelerator by transforming your HuggingFace URLs:

```
Original URL:
https://huggingface.co/internlm/Intern-S1

Xget Accelerated URL:
https://xget.xi-xu.me/hf/internlm/Intern-S1
```

The tool automatically handles this transformation when you use the `--use-xget` flag.

## Usage

### Basic Usage

```bash
python3 transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://your-target.com/repo.git \
  --use-xget
```

### Combined with Mirror Mode

```bash
python3 transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://your-target.com/repo.git \
  --use-xget \
  --mirror
```

### Combined with HF-Transfer (Python)

For maximum performance, combine both acceleration methods:

```bash
# Enable HF-Transfer (Python library acceleration)
export HF_HUB_ENABLE_HF_TRANSFER=1

# Use Xget for git-level acceleration
python3 transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://your-target.com/repo.git \
  --use-xget
```

## Performance Comparison

| Method | Typical Speed | Notes |
|--------|--------------|-------|
| **Standard git clone** | 1x (baseline) | Direct from HuggingFace |
| **HF-Transfer (Python)** | 3-5x faster | Python library acceleration |
| **Xget** | 3-10x faster | CDN + parallel downloads |
| **Xget + HF-Transfer** | 5-15x faster | Combined acceleration |

*Actual performance varies based on network conditions, file sizes, and geographic location*

## Technical Details

### URL Transformation

The tool applies the following transformation:

```python
def _apply_xget_acceleration(url: str) -> str:
    """
    Converts HuggingFace URL to Xget accelerated URL.
    
    Input:  https://huggingface.co/org/model
    Output: https://xget.xi-xu.me/hf/org/model
    """
    if 'huggingface.co' in url:
        url_without_protocol = url.replace('https://', '').replace('http://', '')
        accelerated_path = url_without_protocol.replace('huggingface.co/', '')
        return f'https://xget.xi-xu.me/hf/{accelerated_path}'
    return url
```

### Supported Operations

Xget supports all Git operations:

- ✅ `git clone` - Full repository clone
- ✅ `git clone --mirror` - Mirror clone (all refs)
- ✅ `git pull` - Pull updates
- ✅ `git fetch` - Fetch changes
- ✅ Git LFS operations - Large file support

### Security & Privacy

- **No Logging**: Xget does not store user request data
- **HTTPS Only**: All connections use encrypted HTTPS
- **Direct Pass-through**: Content is proxied, not stored
- **Open Source**: Full transparency via [GitHub repo](https://github.com/xixu-me/Xget)

## When to Use Xget

### ✅ Good Use Cases

- Large model downloads (>1GB)
- Multiple file transfers
- Slow direct connection to HuggingFace
- Geographic distance from HuggingFace servers
- Batch transfers of many models

### ⚠️ May Not Help

- Very small repositories (<100MB)
- Already fast direct connection
- Local network restrictions blocking CDN
- Private/gated repositories (may need credentials)

## Troubleshooting

### Issue: No Speed Improvement

**Possible Causes:**
1. Your direct connection to HuggingFace is already fast
2. CDN edge node not available in your region
3. Network routing issues

**Solution:**
Try with and without `--use-xget` to compare speeds.

### Issue: Connection Failed

**Possible Causes:**
1. Xget service temporarily unavailable
2. Firewall blocking xget.xi-xu.me
3. Network restrictions

**Solution:**
```bash
# Test Xget connectivity
curl -I https://xget.xi-xu.me/

# If it fails, run without --use-xget
python3 transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://your-target.com/repo.git
```

### Issue: Authentication Problems

**Note:** Xget works with public repositories by default. For private repos:

```bash
# HuggingFace credentials still work through Xget
# Set your tokens in .env as usual
HF_TOKEN=your_token_here
HF_USERNAME=your_username

# Run with Xget
python3 transfer.py \
  --source https://huggingface.co/private-org/private-model \
  --target https://your-target.com/repo.git \
  --use-xget
```

## Comparison with Other Methods

| Feature | Standard Clone | HF-Transfer | Xget | Remote Mirror |
|---------|---------------|-------------|------|---------------|
| Speed Boost | - | 3-5x | 3-10x | Server-side |
| Setup Required | None | pip install | None | GitLab API |
| Works with Git | ✅ | ❌ (Python only) | ✅ | ✅ |
| CDN Acceleration | ❌ | ❌ | ✅ | Depends |
| Free to Use | ✅ | ✅ | ✅ | Depends |
| Offline After Clone | ✅ | ✅ | ✅ | ✅ |

## Advanced Usage

### Test URL Transformation

```python
from transfer import ModelTransfer

# Test the transformation
original = "https://huggingface.co/internlm/Intern-S1"
accelerated = ModelTransfer._apply_xget_acceleration(original)

print(f"Original:    {original}")
print(f"Accelerated: {accelerated}")
```

### Benchmark Download Speed

```bash
# Without Xget
time python3 transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://your-target.com/repo.git

# With Xget
time python3 transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://your-target.com/repo.git \
  --use-xget
```

## Limitations

1. **Public Repositories Optimized**: Xget is primarily optimized for public repos
2. **Network-Dependent**: Performance gains depend on your network conditions
3. **CDN Coverage**: Edge node availability varies by region
4. **Third-Party Service**: Depends on Xget service availability

## FAQ

**Q: Do I need to install anything?**  
A: No, just use the `--use-xget` flag. The tool handles everything automatically.

**Q: Does Xget work with private repositories?**  
A: Yes, but you need to provide your HuggingFace credentials in the `.env` file.

**Q: Can I use Xget with other platforms besides HuggingFace?**  
A: Currently, our tool only transforms HuggingFace URLs. Xget supports other platforms, but you'd need to manually construct those URLs.

**Q: Is Xget free?**  
A: Yes, Xget is an open-source project free to use.

**Q: What if Xget is down?**  
A: Simply run the command without `--use-xget` flag, and it will use the standard HuggingFace URL.

## Additional Resources

- **Xget GitHub**: https://github.com/xixu-me/Xget
- **Xget Website**: https://xuc.xi-xu.me
- **HF-Transfer Setup**: [HF_XET_SETUP.md](HF_XET_SETUP.md)
- **Tool Documentation**: [README.md](README.md)

## Contributing

If you encounter issues or have suggestions for improving Xget integration, please:

1. Check if it's a tool issue or Xget issue
2. For tool issues: Open an issue in this repository
3. For Xget issues: Report to [Xget repository](https://github.com/xixu-me/Xget/issues)

---

**Powered by:**
- [Xget](https://github.com/xixu-me/Xget) - Ultra-high-performance acceleration engine
- [HuggingFace](https://huggingface.co) - The AI community platform

**Last Updated:** December 2025

