# Authentication Guide

Understanding when and how to use HuggingFace credentials.

## Do I Need Authentication?

### ✅ NO Authentication Needed

**Public repositories** - Most HuggingFace models are public and can be cloned without credentials:

```bash
# These work without authentication
python3 transfer.py \
  --source https://huggingface.co/gpt2 \
  --target https://target.com/gpt2.git

python3 transfer.py \
  --source https://huggingface.co/bert-base-uncased \
  --target https://target.com/bert.git
```

**You can leave `.env` with placeholder values:**
```bash
HF_TOKEN=hf_your_huggingface_token_here
HF_USERNAME=your_hf_username
```

The tool automatically detects placeholders and skips credential injection.

### ⚠️ Authentication Required

**Private or gated repositories:**

- Private organization models
- Gated models (requiring acceptance of terms)
- Models with restricted access

**Examples:**
- `meta-llama/Llama-2-70b` (gated)
- Your organization's private models
- Models requiring license acceptance

## How to Set Up Authentication

### Step 1: Get Your HuggingFace Token

1. Visit: https://huggingface.co/settings/tokens
2. Click "New token"
3. Select permissions:
   - **Read**: For cloning private/gated repos
   - **Write**: Not needed for cloning
4. Copy the token (starts with `hf_`)

### Step 2: Configure `.env`

```bash
# Edit .env file
nano .env

# Add your real credentials
HF_TOKEN=hf_AbCdEfGhIjKlMnOpQrStUvWxYz1234567890  # Your real token
HF_USERNAME=your_actual_username                   # Your HuggingFace username
```

### Step 3: Verify

```bash
# Test with a gated model
python3 transfer.py \
  --source https://huggingface.co/meta-llama/Llama-2-7b \
  --target https://target.com/llama2.git
```

## Placeholder Detection

The tool automatically detects these as placeholders (won't inject):

- `your_hf_username`
- `hf_your_huggingface_token_here`
- `your_token`
- `placeholder`
- `example`
- `xxx`
- `changeme`
- Any empty value

**Real credentials** (will be injected):
- `hf_AbCdEf123456...` (actual HF token)
- `myusername` (your username)
- Any value not matching placeholder patterns

## Testing Your Setup

### Test 1: Check Placeholder Detection

```bash
python3 << 'EOF'
from transfer import ModelTransfer

# Test your values
token = "hf_your_huggingface_token_here"  # Replace with your value
username = "your_hf_username"              # Replace with your value

mt = ModelTransfer("https://huggingface.co/test", "https://target.com/test")

print(f"Token is placeholder: {mt._is_placeholder(token)}")
print(f"Username is placeholder: {mt._is_placeholder(username)}")

# Should print:
# Token is placeholder: True (if using placeholder)
# Token is placeholder: False (if using real token)
EOF
```

### Test 2: Check Credential Injection

```bash
# Set test values in .env
export HF_TOKEN="your_test_value"
export HF_USERNAME="your_test_username"

# Check what URL will be used
python3 << 'EOF'
import os
from transfer import ModelTransfer

mt = ModelTransfer("https://huggingface.co/test", "https://target.com/test")

url = "https://huggingface.co/test"
token = os.getenv('HF_TOKEN')
username = os.getenv('HF_USERNAME')

result = mt.inject_credentials(url, username, token)
print(f"Original URL: {url}")
print(f"With creds:   {result}")

# Placeholders won't be injected
# Real credentials will be injected
EOF
```

## Common Scenarios

### Scenario 1: All Public Models

```bash
# .env (can use placeholders)
HF_TOKEN=hf_your_huggingface_token_here
HF_USERNAME=your_hf_username

# Or even empty
HF_TOKEN=
HF_USERNAME=

# Transfer works fine
python3 transfer.py --source https://huggingface.co/gpt2 ...
```

### Scenario 2: Mix of Public and Gated

```bash
# .env (use real credentials)
HF_TOKEN=hf_RealToken123456...
HF_USERNAME=myusername

# Public models: credentials sent but not required
python3 transfer.py --source https://huggingface.co/gpt2 ...

# Gated models: credentials required and used
python3 transfer.py --source https://huggingface.co/meta-llama/Llama-2-7b ...
```

### Scenario 3: Private Organization

```bash
# .env (must use real credentials)
HF_TOKEN=hf_RealToken123456...  # With org access
HF_USERNAME=myusername

# Private models
python3 transfer.py --source https://huggingface.co/my-org/private-model ...
```

## Troubleshooting

### Issue: "Repository not found" or "Access denied"

```bash
# Check 1: Is the repository actually public?
# Visit: https://huggingface.co/org/model

# Check 2: Have you accepted the terms (for gated models)?
# Visit the model page and accept terms

# Check 3: Is your token valid?
curl -H "Authorization: Bearer $HF_TOKEN" \
  https://huggingface.co/api/whoami

# Should return your username
```

### Issue: Credentials in URL visible in logs

**This is normal for authenticated requests.** However, the tool tries to keep logs clean:

```bash
# Logs show:
# 🔧 Executing: git clone https://username:***@huggingface.co/model

# Actual command includes full token
# This is necessary for Git authentication
```

**Security tip:** Keep log files private if they contain credentials.

### Issue: Rate limiting even with authentication

```bash
# HTTP 429 error
# Wait and retry:
sleep 300  # 5 minutes
python3 transfer.py ...

# Or use Xget (may have different rate limits)
python3 transfer.py --use-xget ...
```

## Best Practices

### 1. Use Minimal Permissions

- Only request "Read" permission for tokens
- Don't share tokens with write access
- Rotate tokens periodically

### 2. Keep Credentials Secure

```bash
# Never commit .env
git status  # Should show .env in .gitignore

# Set proper permissions
chmod 600 .env

# Don't share logs containing credentials
```

### 3. Test Before Batch Transfers

```bash
# Test authentication with one model first
python3 transfer.py \
  --source https://huggingface.co/gated-model \
  --target https://target.com/test.git

# Then proceed with batch
./batch_transfer_optimized.sh
```

### 4. Use Different Tokens for Different Purposes

```bash
# Development .env
HF_TOKEN=hf_DevToken...

# Production .env
HF_TOKEN=hf_ProdToken...

# CI/CD .env
HF_TOKEN=hf_CIToken...
```

## Environment Variable Priority

The tool looks for credentials in this order:

1. **Inline URL credentials** (highest priority):
   ```bash
   --source https://user:token@huggingface.co/model
   ```

2. **Environment variables** (from `.env` or system):
   ```bash
   HF_TOKEN=...
   HF_USERNAME=...
   ```

3. **No credentials** (lowest priority):
   ```bash
   # Works for public repositories
   ```

## FAQ

**Q: Do I need to set credentials for public models?**  
A: No, public models work without credentials.

**Q: Will placeholders cause errors?**  
A: No, the tool automatically detects and skips placeholders.

**Q: Can I mix real and placeholder values?**  
A: Yes, but if token is real and username is placeholder, only the token will be used.

**Q: Are credentials sent over HTTPS?**  
A: Yes, all Git operations use HTTPS with TLS encryption.

**Q: How do I know if credentials are being used?**  
A: Check the git clone URL in the output. If it contains `username:token@`, credentials are being used.

**Q: What if I forget to set credentials for a gated model?**  
A: You'll see an error: "Repository not found" or "Authentication required". Just set credentials and retry.

## Quick Reference

| Repository Type | Credentials Needed? | How to Set |
|----------------|---------------------|------------|
| Public | ❌ No | Leave placeholders |
| Gated (terms accepted) | ✅ Yes | Set real token |
| Private | ✅ Yes | Set real token + username |
| Organization private | ✅ Yes | Token with org access |

## See Also

- [env.template](env.template) - Environment variable template
- [QUICKSTART.md](QUICKSTART.md) - Quick setup guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues

---

**Last Updated:** December 2025

