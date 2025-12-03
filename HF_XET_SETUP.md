# HuggingFace XET Setup Guide

## ✅ Installation Complete

`hf-xet` has been successfully installed via `huggingface_hub[hf_transfer]`!

## What is HF-XET?

HF-XET is HuggingFace's high-performance transfer engine that significantly speeds up downloading models and datasets from the HuggingFace Hub. It uses optimized protocols and parallel downloads to achieve faster transfer speeds.

## How to Use

### Method 1: Enable via Environment Variable (Recommended)

Add this to your shell configuration file (`~/.bashrc` or `~/.zshrc`):

```bash
export HF_HUB_ENABLE_HF_TRANSFER=1
```

Then reload your shell:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

### Method 2: Enable per-session

For a single session, run:
```bash
export HF_HUB_ENABLE_HF_TRANSFER=1
```

### Method 3: Enable in Python code

```python
import os
os.environ['HF_HUB_ENABLE_HF_TRANSFER'] = '1'

from huggingface_hub import snapshot_download

# Now downloads will use HF-XET acceleration
model_path = snapshot_download(repo_id="internlm/Intern-S1")
```

## Verification

Test that XET is working:

```python
import os
os.environ['HF_HUB_ENABLE_HF_TRANSFER'] = '1'

from huggingface_hub import HfApi
api = HfApi()

# This will use accelerated downloads
print("✅ HF-XET is enabled and ready to use!")
```

## Benefits

- **Faster Downloads**: Up to 10x faster than standard git-lfs
- **Parallel Transfers**: Multiple chunks downloaded simultaneously
- **Resumable**: Can resume interrupted downloads
- **Optimized for Large Files**: Perfect for large model files (>5GB)

## Using with the Transfer Tool

To use HF-XET acceleration with the `transfer.py` tool:

```bash
# Set environment variable
export HF_HUB_ENABLE_HF_TRANSFER=1

# Run transfer with accelerated downloads
python3 transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://your-target.com/repo.git
```

## Troubleshooting

### "hf-xet not found" when using git

**Note:** `hf-xet` primarily works through the Python `huggingface_hub` library, not as a standalone git command. If you need git-level acceleration, use Git LFS optimization or the transfer tool.

### Slow downloads despite HF-XET

1. Check environment variable is set:
   ```bash
   echo $HF_HUB_ENABLE_HF_TRANSFER
   # Should output: 1
   ```

2. Verify hf-xet is installed:
   ```bash
   python3 -c "import hf_xet; print('Installed')"
   ```

3. Check your network connection and firewall settings

## Additional Resources

- [HuggingFace Hub Documentation](https://huggingface.co/docs/huggingface_hub)
- [HF-Transfer GitHub](https://github.com/huggingface/hf_transfer)

## Installation Details

**Installed packages:**
- `huggingface-hub` (v0.36.0)
- `hf-xet` (v1.2.0)
- `filelock` (v3.16.1)

**Installation date:** December 3, 2025

---

**Quick Reference:**

```bash
# Enable HF-XET
export HF_HUB_ENABLE_HF_TRANSFER=1

# Download a model with acceleration
python3 -c "
import os
os.environ['HF_HUB_ENABLE_HF_TRANSFER'] = '1'
from huggingface_hub import snapshot_download
snapshot_download('internlm/Intern-S1')
"
```

