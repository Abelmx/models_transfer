# HuggingFace Model Repository Transfer Tool

A command-line tool to transfer model repositories from HuggingFace to other Git LFS-based platforms such as OpenXlab, ModelScope, or custom GitLab instances.

## Features

- 🚀 Transfer entire model repositories including Git LFS files
- 🔐 Secure credential management via environment variables
- 📦 Automatic Git LFS handling
- 🧹 Automatic cleanup of temporary files
- 🎯 Support for multiple target platforms
- 🪞 Optional remote mirroring mode (GitLab pull mirror) to offload large transfers

## Prerequisites

### System Requirements

1. **Git** - Version 2.0 or higher
   ```bash
   git --version
   ```

2. **Git LFS** - Required for handling large model files
   ```bash
   # Ubuntu/Debian
   sudo apt-get install git-lfs
   
   # macOS
   brew install git-lfs
   
   # Windows
   # Download from https://git-lfs.github.com/
   
   # After installation, initialize git-lfs
   git lfs install
   ```

3. **Python** - Version 3.6 or higher
   ```bash
   python3 --version
   ```

## Installation

1. Clone or download this repository:
   ```bash
   cd /home/maoxin/transfer
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Make the script executable (optional):
   ```bash
   chmod +x transfer.py
   ```

## Configuration

### Setup Environment Variables

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and fill in your credentials:
   ```bash
   nano .env  # or use your preferred editor
   ```

3. Configure your tokens:

   **For HuggingFace:**
   - Get your token from: https://huggingface.co/settings/tokens
   - Set `HF_TOKEN` in `.env`
   - Optionally set `HF_USERNAME` if your repo is private

   **For Target Platform:**
   - Set `TARGET_USERNAME` and `TARGET_TOKEN` according to your platform
   - For GitLab-based platforms (OpenXlab, etc.): Use access tokens
   - For ModelScope: Use your ModelScope credentials

### Example .env Configuration

```bash
# HuggingFace
HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxx
HF_USERNAME=your_hf_username

# Target Platform (e.g., OpenXlab, custom GitLab)
TARGET_USERNAME=your_target_username
TARGET_TOKEN=glpat-your_target_token

# Optional: Pointer-only mode (defaults to 0)
GIT_LFS_SKIP_SMUDGE=0

# Optional: GitLab remote mirroring
MIRROR_PLATFORM=gitlab
GITLAB_API_BASE=https://nm.aihuanxin.cn/api/v4
GITLAB_PROJECT_PATH=qdlake/repo/llm_model/maoxin/Intern-S1
# Use TARGET_TOKEN or set GITLAB_API_TOKEN explicitly
# GITLAB_API_TOKEN=glpat-your_api_token
```

> ⚠️ Set `GIT_LFS_SKIP_SMUDGE=1` only if you explicitly want to push **pointer files without downloading the actual LFS blobs**. The push will fail unless the target platform already hosts the required LFS objects.

### Pointer-only Mode (Advanced)

If you need to mirror only the Git pointer files (no large LFS blobs), set `GIT_LFS_SKIP_SMUDGE=1` in your `.env`. The tool will skip `git lfs fetch/checkout`, drastically reducing network and disk usage.

**Important caveats:**

- Git LFS expects the uploader to provide the blobs. If the target repository does **not** already contain them, pushing in pointer-only mode will fail.
- Even if the push succeeds (e.g., target already has blobs), downstream clones will still need those LFS objects.
- Use this mode only for advanced workflows where LFS blobs are managed outside of this script.

## Usage

### Basic Usage

```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
```

### With Inline Credentials

If you prefer to include credentials in the URL:

```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://username:glpat-your_token@nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
```

### Advanced Options

```bash
# Keep temporary files for inspection
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \
  --no-cleanup

# Use custom .env file
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \
  --env-file /path/to/custom/.env

# Specify custom temporary directory
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \
  --temp-dir /tmp/my_transfer

# Configure GitLab remote mirroring (offload transfer)
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \
  --use-remote-mirror

# Mirror mode: sync ALL refs (branches, tags, remotes)
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \
  --mirror
```

### Command Line Arguments

- `-s, --source`: Source HuggingFace repository URL (required)
- `-t, --target`: Target platform repository URL (required)
- `--temp-dir`: Custom temporary directory for cloning
- `--no-cleanup`: Keep temporary files after transfer
- `--env-file`: Path to custom .env file (default: .env)
- `--mirror`: Mirror mode - clone and push ALL refs (branches, tags, remotes) using `git --mirror`
- `--use-remote-mirror`: Configure remote mirroring (GitLab pull mirror) instead of local transfer
- `-h, --help`: Show help message

### Mirror Mode (Local Full Repository Mirror)

When `--mirror` is set, the tool uses `git clone --mirror` and `git push --mirror` to perform a complete mirror transfer:

**What gets synced:**
- ✅ All branches (not just the default branch)
- ✅ All tags
- ✅ All remote tracking branches
- ✅ All refs (references)

**Use cases:**
- Complete repository backup/migration
- Preserving all repository history and references
- Moving repositories between platforms with full fidelity

**Example:**

```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \
  --mirror
```

**How it works:**

1. Creates a bare mirror clone: `git clone --mirror <source>`
2. Fetches all LFS objects: `git lfs fetch --all`
3. Pushes LFS objects to target: `git lfs push <target> --all`
4. Mirror pushes all refs: `git push --mirror <target>`

**Note:** Mirror mode still requires downloading all data to your local machine (or the machine running the CLI) before pushing to the target. For server-side mirroring that bypasses your machine, see the Remote Mirroring Mode below.

**GitLab Mirror Push Issues:**

When pushing to GitLab with `--mirror`, you may encounter errors like:
- `The default branch of a project cannot be deleted`
- `[remote rejected] master (pre-receive hook declined)`
- `[remote rejected] refs/pr/* (pre-receive hook declined)`

The tool automatically handles these issues by:
1. First attempting a full `git push --mirror`
2. If that fails, falling back to selective push:
   - Pushing all branches: `refs/heads/*:refs/heads/*`
   - Pushing all tags: `refs/tags/*:refs/tags/*`
   - Skipping unsupported refs (like HuggingFace's `refs/pr/*`)

This ensures your repository content is fully transferred even if some GitLab-specific restrictions apply.

---

### Remote Mirroring Mode (GitLab)

When `--use-remote-mirror` is set (and the corresponding environment variables are configured), the CLI skips the local download/push workflow and instead configures a **GitLab pull mirror** via API:

1. Target GitLab project pulls directly from the HuggingFace repository using the credentials you provide.
2. Heavy data transfer happens entirely on the GitLab server—your machine only makes lightweight API calls.
3. Mirroring requires GitLab’s repository mirroring feature (available on self-hosted/community editions with configuration, or GitLab Premium/SaaS accounts that support pull mirrors).

**Required environment variables for GitLab mirror:**

| Variable | Description |
|----------|-------------|
| `MIRROR_PLATFORM` | Set to `gitlab` (default) |
| `GITLAB_API_BASE` | GitLab API base URL (e.g., `https://gitlab.example.com/api/v4`) |
| `GITLAB_PROJECT_PATH` | `<group>/<subgroup>/.../<project>` path |
| `TARGET_TOKEN`/`GITLAB_API_TOKEN` | Token with API + mirror permissions |
| `HF_USERNAME` / `HF_TOKEN` | Credentials GitLab will use to access the HuggingFace repo |

> GitLab pulls on its own schedule (typically every few minutes). You can trigger an immediate sync from the GitLab UI once the mirror is set up.

## How It Works

The tool performs the following steps:

1. **Clone Source Repository** 📥
   - Clones the repository from HuggingFace
   - Initially skips LFS files for faster cloning

2. **Fetch LFS Files** 📦
   - Downloads all Git LFS files
   - Checks out LFS files to working directory

3. **Change Remote** 🔄
   - Removes the original remote
   - Adds the target platform as new remote

4. **Push to Target** 📤
   - Pushes all branches to target platform
   - Pushes all tags
   - Uses force push to handle repository initialization

5. **Cleanup** 🧹
   - Removes temporary files (unless --no-cleanup is used)

## Supported Platforms

This tool works with any Git LFS-based platform, including:

- ✅ **OpenXlab** - AI model hosting platform
- ✅ **ModelScope** - Alibaba's model repository
- ✅ **GitLab** - Self-hosted or GitLab.com
- ✅ **Custom Git LFS Servers** - Any platform supporting Git LFS

## Troubleshooting

### Issue: "git-lfs is not installed"

**Solution:**
```bash
# Install git-lfs
sudo apt-get install git-lfs  # Ubuntu/Debian
brew install git-lfs          # macOS

# Initialize git-lfs
git lfs install
```

### Issue: Authentication Failed

**Solution:**
1. Verify your tokens are correct in `.env`
2. Check token permissions (needs read/write access)
3. For HuggingFace: Ensure token has repository access
4. For target platform: Ensure token has push permissions

### Issue: Large Files Not Transferred

**Solution:**
1. Verify Git LFS is installed: `git lfs version`
2. Check LFS configuration in source repository
3. Ensure target platform supports Git LFS

### Issue: Push Failed - Repository Doesn't Exist

**Solution:**
1. Create the target repository on the target platform first
2. Ensure the repository URL is correct
3. Verify you have push access to the repository

### Issue: Mirror Push Failed - "The default branch cannot be deleted"

**Problem:**
When using `--mirror` mode with GitLab, you see:
```
remote: GitLab: The default branch of a project cannot be deleted.
[remote rejected] master (pre-receive hook declined)
[remote rejected] refs/pr/* (pre-receive hook declined)
```

**Solution:**
The tool automatically handles this by falling back to selective push. However, if you're doing manual mirror push:

```bash
# Method 1: Use the tool (handles automatically)
python3 transfer.py --source <URL> --target <URL> --mirror

# Method 2: Manual selective push
cd /path/to/mirror/repo
git push <target> 'refs/heads/*:refs/heads/*' --force
git push <target> 'refs/tags/*:refs/tags/*' --force

# Method 3: Temporarily disable GitLab branch protection
# 1. GitLab UI → Settings → Repository → Protected branches
# 2. Unprotect the default branch
# 3. Run: git push --mirror <target> --force
# 4. Re-enable protection
```

**Why this happens:**
- GitLab protects default branches from deletion
- `git push --mirror` tries to sync ALL refs, including deletions
- HuggingFace repos contain `refs/pr/*` which GitLab doesn't support
- The tool's fallback strategy pushes only branches and tags

## Additional Documentation

For more detailed information, see:

- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Detailed solutions for common issues
- **[PLATFORM_GUIDE.md](PLATFORM_GUIDE.md)** - Platform-specific configuration
- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute quick start guide
- **[PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)** - Project organization and development

## Security Notes

- ⚠️ **Never commit your `.env` file** to version control
- ⚠️ Keep your tokens secure and rotate them regularly
- ⚠️ Use tokens with minimum required permissions
- ⚠️ The `.env` file is already added to `.gitignore`

## Examples

### Example 1: Transfer Intern-S1 to OpenXlab

```bash
# Configure .env
cat > .env << EOF
HF_TOKEN=hf_your_token
TARGET_USERNAME=your_username
TARGET_TOKEN=glpat-your_token
EOF

# Run transfer
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://openxlab.org.cn/your_username/Intern-S1.git
```

### Example 2: Transfer to ModelScope

```bash
python transfer.py \
  --source https://huggingface.co/meta-llama/Llama-2-7b \
  --target https://modelscope.cn/your_username/Llama-2-7b.git
```

### Example 3: Transfer Multiple Models (Batch)

```bash
#!/bin/bash
# batch_transfer.sh

models=(
  "internlm/Intern-S1"
  "internlm/internlm2-chat-7b"
  "internlm/internlm2-chat-20b"
)

for model in "${models[@]}"; do
  model_name=$(basename $model)
  python transfer.py \
    --source "https://huggingface.co/$model" \
    --target "https://your-platform.com/your_username/$model_name.git"
done
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This tool is provided as-is for transferring model repositories. Please ensure you comply with the licenses of the models you transfer.

## References

- [HuggingFace Documentation](https://huggingface.co/docs)
- [Git LFS Documentation](https://git-lfs.github.com/)
- [Intern-S1 Model](https://huggingface.co/internlm/Intern-S1)

