# Quick Start Guide

Get started with the HuggingFace Model Transfer Tool in 5 minutes.

## Prerequisites Check

```bash
# Check Git
git --version
# Should show: git version 2.x.x or higher

# Check Git LFS
git lfs version
# Should show: git-lfs/2.x.x or higher

# Check Python
python3 --version
# Should show: Python 3.6 or higher
```

If any of these are missing, see the installation guide in [README.md](README.md).

## Step-by-Step Setup

### 1. Install Dependencies

```bash
cd /home/maoxin/transfer
pip install -r requirements.txt
```

### 2. Configure Credentials

Copy the template and edit with your credentials:

```bash
cp env.template .env
nano .env  # or use vim, code, etc.
```

Add your tokens to `.env`:

```bash
# HuggingFace token (get from https://huggingface.co/settings/tokens)
HF_TOKEN=hf_your_token_here
HF_USERNAME=your_hf_username

# Target platform credentials
TARGET_USERNAME=your_target_username
TARGET_TOKEN=glpat-your_token_here

# Optional: pointer-only mode (default 0)
GIT_LFS_SKIP_SMUDGE=0

# Optional: GitLab remote mirroring
MIRROR_PLATFORM=gitlab
GITLAB_API_BASE=https://nm.aihuanxin.cn/api/v4
GITLAB_PROJECT_PATH=qdlake/repo/llm_model/your_name/YourModel
# GITLAB_API_TOKEN=glpat-your_api_token  # Defaults to TARGET_TOKEN
```

Save and exit.

> Set `GIT_LFS_SKIP_SMUDGE=1` **only** if you need to sync pointer files without downloading LFS blobs. The target repository must already contain the required LFS objects or the push will fail.

> Use the GitLab mirroring variables only if your target server supports pull mirroring and you plan to run `--use-remote-mirror`.

### 3. Run Your First Transfer

```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
```

## What Happens During Transfer

```
📥 Step 1: Cloning from HuggingFace
├── Clones the repository
└── Skips LFS files initially (for speed)

📦 Step 2: Fetching Git LFS files
├── Downloads all large files
└── Checks them out to working directory

🔄 Step 3: Changing remote
├── Removes HuggingFace remote
└── Adds target platform remote

📤 Step 4: Pushing to target
├── Pushes all branches
└── Pushes all tags

🧹 Step 5: Cleanup
└── Removes temporary files
```

## Common Scenarios

### Scenario 1: Transfer to Your GitLab Instance

```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
```

### Scenario 2: Transfer with Credentials in URL

If you prefer not to use `.env`:

```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://maoxin:glpat-token@nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
```

### Scenario 3: Mirror Mode (Sync ALL Refs)

Transfer ALL branches, tags, and refs:

```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \
  --mirror
```

This uses `git clone --mirror` and `git push --mirror` to create a complete repository mirror.

### Scenario 4: Debug Mode (Keep Files)

```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \
  --no-cleanup
```

Files will be kept in `/tmp/hf_transfer_*` for inspection.

### Scenario 5: Transfer Multiple Models
# Scenario 5: Remote mirroring (GitLab pull mirror)
```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \
  --use-remote-mirror
```

GitLab will create/update a pull mirror pointing to HuggingFace and sync in the background. Make sure the environment variables for mirroring are set.

Edit `batch_transfer.sh` and add your models:

```bash
MODELS=(
    "https://huggingface.co/internlm/Intern-S1|https://nm.aihuanxin.cn/.../Intern-S1.git"
    "https://huggingface.co/internlm/internlm2-chat-7b|https://nm.aihuanxin.cn/.../internlm2-chat-7b.git"
)
```

Then run:

```bash
./batch_transfer.sh
```

## Verification

After transfer, verify on your target platform:

1. Visit your repository URL in a browser
2. Check that all files are present
3. Verify LFS files are showing correct sizes
4. Clone the repository to test:
   ```bash
   git clone <target_url> test-clone
   cd test-clone
   git lfs pull
   ```

## Troubleshooting Quick Fixes

### Issue: "git-lfs is not installed"

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install git-lfs
git lfs install

# macOS
brew install git-lfs
git lfs install
```

### Issue: "Authentication failed"

1. Check your tokens in `.env`
2. Verify token permissions
3. For HuggingFace: Token needs "Read" access
4. For target: Token needs "Write" access

### Issue: "Repository does not exist"

Create the repository on the target platform first:
- Go to your platform's web interface
- Create a new repository with the same name
- Then run the transfer

### Issue: "Out of disk space"

Large models need space:
- Check: `df -h /tmp`
- Clean temp files: `rm -rf /tmp/hf_transfer_*`
- Use custom temp dir: `--temp-dir /path/with/space`

## Performance Tips

### For Large Models (>10GB)

1. **Use a machine with good bandwidth**
   - Upload speed matters for pushing to target
   - Download speed matters for cloning from HF

2. **Monitor disk space**
   ```bash
   # Check available space
   df -h /tmp
   
   # Use custom temp directory with more space
   python transfer.py --temp-dir /mnt/large-disk/transfer ...
   ```

3. **Run in screen/tmux for long transfers**
   ```bash
   screen -S transfer
   python transfer.py --source ... --target ...
   # Detach: Ctrl+A, then D
   # Reattach: screen -r transfer
   ```

### For Multiple Models

Use the batch transfer script:

```bash
./batch_transfer.sh
```

Or create a simple loop:

```bash
for model in model1 model2 model3; do
  python transfer.py \
    --source https://huggingface.co/org/$model \
    --target https://your-platform.com/org/$model.git
done
```

## Next Steps

- Read [PLATFORM_GUIDE.md](PLATFORM_GUIDE.md) for platform-specific configuration
- See [README.md](README.md) for complete documentation
- Check [example_usage.sh](example_usage.sh) for more examples

## Getting Help

Run with `-h` for all options:

```bash
python transfer.py --help
```

View examples:

```bash
./example_usage.sh
```

## Success! 🎉

If you see:

```
🎉 Transfer completed successfully!
```

Your model has been transferred! Visit your target platform to verify.

---

**Important Security Notes:**

- ⚠️ Never commit your `.env` file
- ⚠️ Keep your tokens secure
- ⚠️ Use tokens with minimum required permissions
- ⚠️ Rotate tokens regularly

