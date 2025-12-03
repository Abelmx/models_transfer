# Troubleshooting Guide

Common issues and solutions for the HuggingFace Model Transfer Tool.

## Table of Contents

- [Mirror Push Issues](#mirror-push-issues)
- [Authentication Problems](#authentication-problems)
- [Git LFS Issues](#git-lfs-issues)
- [GitLab-Specific Issues](#gitlab-specific-issues)
- [General Issues](#general-issues)

---

## Mirror Push Issues

### "The default branch of a project cannot be deleted"

**Symptom:**
```bash
$ git push --mirror target
remote: GitLab: The default branch of a project cannot be deleted.
! [remote rejected] master (pre-receive hook declined)
! [remote rejected] main -> main (pre-receive hook declined)
! [remote rejected] refs/pr/10 -> refs/pr/10 (pre-receive hook declined)
error: failed to push some refs
```

**Root Cause:**
- `git push --mirror` tries to synchronize ALL refs, including deletions
- GitLab protects the default branch from being deleted
- HuggingFace repos contain `refs/pr/*` (pull request refs) that GitLab doesn't support

**Solution 1: Use the CLI Tool (Automatic Handling)**

The tool automatically handles this issue:

```bash
python3 transfer.py \
  --source https://huggingface.co/internlm/Intern-S1 \
  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \
  --mirror
```

The tool will:
1. Try `git push --mirror` first
2. If it fails, automatically fall back to selective push
3. Push branches: `refs/heads/*:refs/heads/*`
4. Push tags: `refs/tags/*:refs/tags/*`
5. Skip unsupported refs like `refs/pr/*`

**Solution 2: Manual Selective Push**

If you're already in a mirror directory:

```bash
cd ~/transfer/intern-s1.git

# Push LFS objects first
git lfs push target --all

# Push all branches (force update)
git push target 'refs/heads/*:refs/heads/*' --force

# Push all tags (force update)
git push target 'refs/tags/*:refs/tags/*' --force
```

**Solution 3: Temporarily Disable GitLab Protection**

⚠️ Use with caution in production environments!

1. Go to GitLab project → **Settings** → **Repository** → **Protected branches**
2. Click **Unprotect** on the default branch (main/master)
3. Run the mirror push:
   ```bash
   git push --mirror target --force
   ```
4. Re-enable branch protection in GitLab

**Solution 4: Filter Out Problematic Refs**

```bash
# Push everything except PR refs
git for-each-ref --format='%(refname)' refs/heads refs/tags | \
  xargs -I {} git push target {} --force
```

---

## Authentication Problems

### "Authentication failed"

**Symptom:**
```
fatal: Authentication failed for 'https://...'
```

**Solutions:**

1. **Check your `.env` file:**
   ```bash
   cat .env
   # Verify HF_TOKEN, TARGET_USERNAME, TARGET_TOKEN are set correctly
   ```

2. **Verify token permissions:**
   - HuggingFace: Token needs "Read" access
   - Target platform: Token needs "Write" and "API" access

3. **Test credentials manually:**
   ```bash
   # Test HuggingFace
   git ls-remote https://<username>:<token>@huggingface.co/repo/model

   # Test target platform
   git ls-remote https://<username>:<token>@target.com/repo.git
   ```

4. **Check token format:**
   - HuggingFace: `hf_xxxxxxxxxxxxxxxxxxxx`
   - GitLab: `glpat-xxxxxxxxxxxxxxxxxxxx`
   - GitHub: `ghp_xxxxxxxxxxxxxxxxxxxx`

### "remote: HTTP Basic: Access denied"

**Cause:** Token expired or insufficient permissions

**Solution:**
1. Generate a new token with required scopes:
   - GitLab: `api`, `read_repository`, `write_repository`
   - GitHub: `repo` (full control)
2. Update your `.env` file
3. Retry the transfer

---

## Git LFS Issues

### "batch request: git-lfs/objects/batch API not found"

**Symptom:**
```
batch request: git-lfs/objects/batch API not found
error: failed to push some refs
```

**Cause:** Target platform doesn't support Git LFS or it's not enabled

**Solutions:**

1. **Verify LFS is enabled on target platform:**
   ```bash
   # Check if target repo supports LFS
   git lfs ls-files
   ```

2. **For GitLab self-hosted:**
   - Admin must enable Git LFS in gitlab.rb
   - Check: Settings → General → Visibility → Git LFS

3. **Use pointer-only mode (advanced):**
   ```bash
   # Set in .env
   GIT_LFS_SKIP_SMUDGE=1
   
   # Run transfer
   python3 transfer.py --source <URL> --target <URL>
   ```
   ⚠️ This only pushes pointer files, not actual LFS objects

### "LFS objects missing after push"

**Solution:**

1. **Manually push LFS objects:**
   ```bash
   cd /path/to/repo
   git lfs push origin --all
   ```

2. **Verify LFS installation:**
   ```bash
   git lfs version
   git lfs install
   ```

3. **Check LFS tracking:**
   ```bash
   cat .gitattributes
   # Should show patterns like: *.bin filter=lfs diff=lfs merge=lfs
   ```

---

## GitLab-Specific Issues

### "Project not found" when using API mirror

**Symptom:**
```
Failed to fetch GitLab project: 404 Not Found
```

**Solutions:**

1. **Check `GITLAB_PROJECT_PATH` format:**
   ```bash
   # Correct format: group/subgroup/project
   GITLAB_PROJECT_PATH=qdlake/repo/llm_model/maoxin/Intern-S1
   
   # NOT: /qdlake/repo/... (no leading slash)
   # NOT: ...Intern-S1.git (no .git suffix)
   ```

2. **Verify project exists:**
   - Visit the project in GitLab UI
   - Copy the project path from Settings → General

3. **Check token permissions:**
   ```bash
   # Token must have 'api' scope
   curl -H "PRIVATE-TOKEN: <your_token>" \
     https://gitlab.example.com/api/v4/projects/group%2Fproject
   ```

### "SSL certificate problem"

**Symptom:**
```
SSL certificate problem: self signed certificate
```

**Temporary workaround (NOT for production):**
```bash
export GIT_SSL_NO_VERIFY=1
python3 transfer.py ...
```

**Proper solution:**
1. Install the CA certificate:
   ```bash
   # Ubuntu/Debian
   sudo cp certificate.crt /usr/local/share/ca-certificates/
   sudo update-ca-certificates
   ```

2. Configure Git to use it:
   ```bash
   git config --global http.sslCAInfo /path/to/certificate.crt
   ```

---

## General Issues

### "No space left on device"

**Cause:** Large model files fill up `/tmp`

**Solutions:**

1. **Use custom temp directory:**
   ```bash
   python3 transfer.py \
     --source <URL> \
     --target <URL> \
     --temp-dir /mnt/large-disk/transfer
   ```

2. **Check disk space:**
   ```bash
   df -h /tmp
   df -h /home
   ```

3. **Clean up old transfers:**
   ```bash
   rm -rf /tmp/hf_transfer_*
   ```

### "Transfer is too slow"

**Solutions:**

1. **Use pointer-only mode (if applicable):**
   ```bash
   # In .env
   GIT_LFS_SKIP_SMUDGE=1
   ```

2. **Use remote mirroring (GitLab only):**
   ```bash
   python3 transfer.py \
     --source <URL> \
     --target <URL> \
     --use-remote-mirror
   ```
   This offloads the transfer to GitLab's servers.

3. **Run on a cloud VM:**
   - Better bandwidth than local machine
   - Closer to source/target servers

### "Command not found: python3"

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get install python3 python3-pip

# macOS
brew install python3

# Or use python instead
alias python3=python
```

### "git-lfs is not installed"

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get install git-lfs
git lfs install

# macOS
brew install git-lfs
git lfs install

# Windows
# Download from: https://git-lfs.github.com/
```

---

## Debug Tips

### Enable verbose output

```bash
# Set Git to verbose mode
export GIT_TRACE=1
export GIT_CURL_VERBOSE=1

# Run transfer
python3 transfer.py --source <URL> --target <URL> --no-cleanup
```

### Inspect temporary files

```bash
# Use --no-cleanup to keep temp files
python3 transfer.py \
  --source <URL> \
  --target <URL> \
  --no-cleanup

# Check the temp directory
ls -lah /tmp/hf_transfer_*/
cd /tmp/hf_transfer_*/repo
git log --oneline
git lfs ls-files
```

### Test connection manually

```bash
# Test source (HuggingFace)
git ls-remote https://huggingface.co/internlm/Intern-S1

# Test target
git ls-remote https://<user>:<token>@target.com/repo.git

# Test LFS endpoint
git lfs env
```

---

## Getting More Help

If you're still stuck:

1. **Check the main documentation:**
   - `README.md` - Complete guide
   - `QUICKSTART.md` - Quick setup
   - `PLATFORM_GUIDE.md` - Platform-specific help

2. **Run with debug mode:**
   ```bash
   python3 transfer.py --source <URL> --target <URL> --no-cleanup
   ```
   Then inspect the temp directory for clues.

3. **Check platform documentation:**
   - [HuggingFace Git Docs](https://huggingface.co/docs/hub/repositories-getting-started)
   - [GitLab API Docs](https://docs.gitlab.com/ee/api/)
   - [Git LFS Docs](https://git-lfs.github.com/)

4. **Verify prerequisites:**
   ```bash
   git --version          # Should be 2.0+
   git lfs version        # Should be 2.0+
   python3 --version      # Should be 3.6+
   ```

---

## Common Error Messages Quick Reference

| Error | Quick Fix |
|-------|-----------|
| `The default branch cannot be deleted` | Tool handles automatically; or use selective push |
| `Authentication failed` | Check tokens in `.env` |
| `git-lfs API not found` | Verify LFS enabled on target |
| `No space left on device` | Use `--temp-dir` on larger disk |
| `SSL certificate problem` | Install CA cert or set `GIT_SSL_NO_VERIFY=1` |
| `Project not found` | Check `GITLAB_PROJECT_PATH` format |
| `remote rejected refs/pr/*` | Normal - PR refs not supported on GitLab |
| `git-lfs is not installed` | Install: `apt install git-lfs && git lfs install` |

---

**Last Updated:** December 2025  
**Tool Version:** 1.0.0

