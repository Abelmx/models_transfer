# Platform Configuration Guide

This guide provides configuration examples for different target platforms.

## Table of Contents

- [HuggingFace (Source)](#huggingface-source)
- [OpenXlab](#openxlab)
- [ModelScope](#modelscope)
- [GitLab (Self-hosted)](#gitlab-self-hosted)
- [Custom Platforms](#custom-platforms)
- [Remote Mirroring (GitLab)](#remote-mirroring-gitlab)

---

## HuggingFace (Source)

### Get Your Token

1. Visit: https://huggingface.co/settings/tokens
2. Click "New token"
3. Select "Read" permission (or "Write" if you need it)
4. Copy the token

### .env Configuration

```bash
HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxx
HF_USERNAME=your_username  # Optional, only needed for private repos
```

### URL Format

```
https://huggingface.co/{username}/{model_name}
```

**Example:**
```
https://huggingface.co/internlm/Intern-S1
```

---

## OpenXlab

OpenXlab is a Chinese AI model hosting platform that uses GitLab under the hood.

### Get Your Token

1. Visit OpenXlab website and log in
2. Go to Settings → Access Tokens
3. Create a new access token with `api`, `read_repository`, and `write_repository` scopes
4. Copy the token (starts with `glpat-`)

### .env Configuration

```bash
TARGET_USERNAME=your_openxlab_username
TARGET_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
```

### URL Format

```
https://code.openxlab.org.cn/{username}/{model_name}.git
```

**Example:**
```
https://code.openxlab.org.cn/maoxin/Intern-S1.git
```

### Complete Example

```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://code.openxlab.org.cn/maoxin/Intern-S1.git
```

---

## ModelScope

ModelScope is Alibaba's model repository platform.

### Get Your Token

1. Visit: https://modelscope.cn
2. Log in and go to your account settings
3. Generate an access token
4. Copy the token

### .env Configuration

```bash
TARGET_USERNAME=your_modelscope_username
TARGET_TOKEN=your_modelscope_token
```

### URL Format

```
https://www.modelscope.cn/api/v1/models/{username}/{model_name}.git
```

or

```
https://modelscope.cn/{username}/{model_name}.git
```

**Example:**
```
https://www.modelscope.cn/api/v1/models/maoxin/Intern-S1.git
```

### Complete Example

```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://www.modelscope.cn/api/v1/models/maoxin/Intern-S1.git
```

---

## GitLab (Self-hosted)

For custom GitLab instances or self-hosted GitLab servers.

### Get Your Token

1. Log in to your GitLab instance
2. Go to User Settings → Access Tokens
3. Create a new token with `api`, `read_repository`, and `write_repository` scopes
4. Copy the token (starts with `glpat-`)

### .env Configuration

```bash
TARGET_USERNAME=your_gitlab_username
TARGET_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx
```

### URL Format

```
https://{gitlab_domain}/{group}/{project}.git
```

**Example (from your requirement):**
```
https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
```

### Complete Example

```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
```

### With Inline Credentials

```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://username:glpat-your_token@nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
```

### Remote Mirroring (GitLab)

If your GitLab instance supports **pull mirroring**, you can offload the heavy transfer workload to the GitLab server itself. Enable it by setting the mirroring environment variables and passing `--use-remote-mirror` to the CLI.

**Required environment variables:**

```bash
MIRROR_PLATFORM=gitlab
GITLAB_API_BASE=https://nm.aihuanxin.cn/api/v4
GITLAB_PROJECT_PATH=qdlake/repo/llm_model/maoxin/Intern-S1
# Optional: override API token (defaults to TARGET_TOKEN)
# GITLAB_API_TOKEN=glpat-your_api_token
# Optional: limit mirrored branches
# GITLAB_MIRROR_BRANCH_REGEX=main|release/.*
```

**Command:**

```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \
  --use-remote-mirror
```

**How it works:**

1. The CLI calls the GitLab API to create/update a pull mirror pointing to the HuggingFace repo (credentials are embedded in the mirror URL).
2. GitLab pulls from HuggingFace on its own schedule (you can force a sync from the GitLab UI).
3. No large files flow through your local machine—only lightweight API requests are made.

> GitLab’s pull mirroring feature might require GitLab Premium/SaaS or specific configuration on self-hosted instances. Ensure your license/instance allows pull mirrors and that the PAT (`TARGET_TOKEN`/`GITLAB_API_TOKEN`) has `api` scope plus mirror permissions.

---

## Custom Platforms

For other platforms that support Git LFS.

### General Steps

1. **Identify authentication method:**
   - Personal Access Token (PAT)
   - OAuth token
   - Username/Password
   - SSH keys (not supported by this tool - use HTTPS)

2. **Get your credentials:**
   - Check platform documentation for token generation
   - Note the token prefix (if any): `glpat-`, `ghp_`, etc.

3. **Find the Git URL format:**
   - Look in the platform's documentation
   - Usually: `https://{domain}/{path}/{repo}.git`

4. **Configure .env:**
   ```bash
   TARGET_USERNAME=your_username
   TARGET_TOKEN=your_token
   ```

5. **Test with a small repository first!**

### Common URL Patterns

| Platform Type | URL Format |
|--------------|------------|
| GitHub | `https://github.com/{user}/{repo}.git` |
| GitLab | `https://gitlab.com/{user}/{repo}.git` |
| Gitea | `https://{domain}/{user}/{repo}.git` |
| Bitbucket | `https://bitbucket.org/{user}/{repo}.git` |

---

## Troubleshooting by Platform

### OpenXlab Issues

**Problem:** Push rejected
```
Solution: Ensure your repository exists and you have write access
```

**Problem:** LFS files not appearing
```
Solution: Verify OpenXlab supports Git LFS (it should)
```

### ModelScope Issues

**Problem:** Authentication failed
```
Solution: ModelScope may require specific API endpoints. Check their docs.
```

**Problem:** Invalid URL
```
Solution: Use the /api/v1/models/ path in the URL
```

### Self-hosted GitLab Issues

**Problem:** SSL certificate errors
```bash
# Temporary workaround (NOT recommended for production):
export GIT_SSL_NO_VERIFY=1

# Better: Install proper SSL certificates
```

**Problem:** Git LFS not enabled
```
Solution: Admin must enable Git LFS in GitLab settings
```

---

## Complete Configuration Examples

### Example 1: HF → OpenXlab

**.env:**
```bash
HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxx
TARGET_USERNAME=maoxin
TARGET_TOKEN=glpat-your_token_here
```

**Command:**
```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://code.openxlab.org.cn/maoxin/Intern-S1.git
```

### Example 2: HF → ModelScope

**.env:**
```bash
HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxx
TARGET_USERNAME=maoxin
TARGET_TOKEN=ms_your_token_here
```

**Command:**
```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://www.modelscope.cn/api/v1/models/maoxin/Intern-S1.git
```

### Example 3: HF → Custom GitLab

**.env:**
```bash
HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxx
TARGET_USERNAME=maoxin
TARGET_TOKEN=glpat-your_token_here
```

**Command:**
```bash
python transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git
```

---

## Best Practices

1. **Always test with a small model first** before transferring large models
2. **Create the target repository** on the platform before running the transfer
3. **Use tokens with minimum required permissions** (read for source, write for target)
4. **Keep your .env file secure** and never commit it
5. **Use --no-cleanup flag** for the first run to debug issues
6. **Monitor disk space** as large models will be cloned to temp directory

---

## Getting Help

If you encounter issues:

1. Check if Git LFS is installed: `git lfs version`
2. Verify your tokens are correct and have proper permissions
3. Test Git operations manually:
   ```bash
   git clone <source_url>
   cd repo
   git remote set-url origin <target_url>
   git push origin main
   ```
4. Use `--no-cleanup` to inspect temporary files
5. Check platform-specific documentation for Git/LFS support

---

## Additional Resources

- [HuggingFace Git Documentation](https://huggingface.co/docs/hub/repositories-getting-started)
- [Git LFS Documentation](https://git-lfs.github.com/)
- [OpenXlab Documentation](https://openxlab.org.cn/docs)
- [ModelScope Documentation](https://modelscope.cn/docs)

