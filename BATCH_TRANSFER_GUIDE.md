# Batch Transfer Guide

Complete guide for batch transferring multiple HuggingFace models with optimal performance.

## Quick Start

### 1. Create Configuration File

```bash
# Copy the example config
cp batch_config.example.txt batch_config.txt

# Edit with your models
nano batch_config.txt
```

### 2. Run Batch Transfer

```bash
# Basic usage (best performance by default)
./batch_transfer_optimized.sh

# With custom target base URL
./batch_transfer_optimized.sh --target-base https://your-platform.com/models

# Dry run first (preview without transferring)
./batch_transfer_optimized.sh --dry-run
```

## Configuration File Format

### Method 1: Full URL Specification

```txt
# Format: source_repo|target_url
internlm/Intern-S1|https://target.com/Intern-S1.git
meta-llama/Llama-2-7b|https://target.com/Llama-2-7b.git
```

### Method 2: Using Target Base URL

```txt
# Just list the models
internlm/Intern-S1
meta-llama/Llama-2-7b

# Then run with --target-base
./batch_transfer_optimized.sh --target-base https://target.com/models
```

### Comments and Empty Lines

```txt
# This is a comment
# Empty lines are ignored

internlm/Intern-S1|https://target.com/Intern-S1.git

# Another comment
meta-llama/Llama-2-7b|https://target.com/Llama-2-7b.git
```

## Command Line Options

### Performance Options

```bash
# Best performance (default) - Xget + HF-Transfer
./batch_transfer_optimized.sh

# Xget only
./batch_transfer_optimized.sh --no-hf-transfer

# HF-Transfer only  
./batch_transfer_optimized.sh --no-xget

# Standard (no acceleration)
./batch_transfer_optimized.sh --no-xget --no-hf-transfer
```

### Transfer Options

```bash
# Mirror mode (all refs)
./batch_transfer_optimized.sh --mirror

# Remote mirroring (GitLab)
./batch_transfer_optimized.sh --use-remote-mirror

# Keep temporary files
./batch_transfer_optimized.sh --no-cleanup
```

### Error Handling & Rate Limiting

```bash
# Continue even if some transfers fail
./batch_transfer_optimized.sh --continue-on-error

# Set maximum retry attempts
./batch_transfer_optimized.sh --max-retries 3

# Add delay between models to avoid rate limits (HTTP 429)
./batch_transfer_optimized.sh --delay 30  # 30 seconds between models

# Combine for robust batch transfer
./batch_transfer_optimized.sh \
  --continue-on-error \
  --max-retries 3 \
  --delay 60
```

### Other Options

```bash
# Custom config file
./batch_transfer_optimized.sh --config my_models.txt

# Dry run (preview)
./batch_transfer_optimized.sh --dry-run

# Show help
./batch_transfer_optimized.sh --help
```

## Complete Examples

### Example 1: Basic Transfer with Best Performance

```bash
# 1. Create config
cat > batch_config.txt << EOF
internlm/Intern-S1|https://nm.aihuanxin.cn/models/Intern-S1.git
internlm/internlm2-chat-7b|https://nm.aihuanxin.cn/models/internlm2-chat-7b.git
EOF

# 2. Run transfer (Xget + HF-Transfer enabled by default)
./batch_transfer_optimized.sh

# Output:
# ✓ Model 1/2 transferred successfully
# ✓ Model 2/2 transferred successfully
# Performance: BEST PERFORMANCE (5-15x faster)
```

### Example 2: Using Target Base URL

```bash
# 1. Create config (simple format)
cat > batch_config.txt << EOF
internlm/Intern-S1
meta-llama/Llama-2-7b
openai/whisper-large
EOF

# 2. Run with target base
./batch_transfer_optimized.sh \
  --target-base https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin

# URLs are automatically constructed:
#   https://nm.aihuanxin.cn/.../Intern-S1.git
#   https://nm.aihuanxin.cn/.../Llama-2-7b.git
#   https://nm.aihuanxin.cn/.../whisper-large.git
```

### Example 3: Mirror Mode with Retry

```bash
# Transfer with mirror mode and increased retry
./batch_transfer_optimized.sh \
  --mirror \
  --max-retries 3 \
  --continue-on-error
```

### Example 4: Preview Before Transfer

```bash
# Dry run to see what will happen
./batch_transfer_optimized.sh --dry-run

# Output shows:
#   Would execute: python3 transfer.py --source ... --target ... --use-xget
```

## Performance Comparison

| Mode | Command | Speed | Use Case |
|------|---------|-------|----------|
| **Best** ⭐ | Default | 5-15x | Recommended for all |
| Xget Only | `--no-hf-transfer` | 3-10x | Git operations |
| HF-Transfer Only | `--no-xget` | 3-5x | Python API heavy |
| Standard | `--no-xget --no-hf-transfer` | 1x | Baseline |

## Log Files

Each run creates a detailed log file:

```bash
# Log file name format
batch_transfer_YYYYMMDD_HHMMSS.log

# View the latest log
ls -t batch_transfer_*.log | head -1 | xargs cat

# Monitor in real-time
tail -f batch_transfer_*.log
```

## Error Handling

### Default Behavior

By default, the script stops on first failure:

```bash
./batch_transfer_optimized.sh

# If model 2 fails, models 3-10 are skipped
# Exit code: 1 (failure)
```

### Continue on Error

```bash
./batch_transfer_optimized.sh --continue-on-error

# If model 2 fails, continues with models 3-10
# Exit code: 2 (partial success)
```

### Retry Logic

```bash
# Default: 2 retries per model
./batch_transfer_optimized.sh

# Custom retry count
./batch_transfer_optimized.sh --max-retries 5

# No retries
./batch_transfer_optimized.sh --max-retries 0
```

## Exit Codes

- `0` - All transfers successful
- `1` - All transfers failed
- `2` - Some transfers failed (with --continue-on-error)

## Best Practices

### 1. Start Small

```bash
# Test with one small model first
cat > test_config.txt << EOF
gpt2
EOF

./batch_transfer_optimized.sh --config test_config.txt --dry-run
./batch_transfer_optimized.sh --config test_config.txt
```

### 2. Use Dry Run

```bash
# Always preview first
./batch_transfer_optimized.sh --dry-run

# Review output, then run for real
./batch_transfer_optimized.sh
```

### 3. Monitor Progress

```bash
# Run in background with log monitoring
./batch_transfer_optimized.sh > /dev/null 2>&1 &

# Monitor the log
tail -f batch_transfer_*.log
```

### 4. Group Similar Models

```bash
# Group by size for better time estimation
# Small models first for quick validation
cat > batch_config.txt << EOF
# Small models (< 1GB)
distilbert-base-uncased
gpt2

# Medium models (1-10GB)  
bert-large-uncased
t5-large

# Large models (> 10GB)
internlm/Intern-S1
meta-llama/Llama-2-7b
EOF
```

### 5. Use Continue-on-Error for Large Batches

```bash
# For 10+ models, continue even if some fail
./batch_transfer_optimized.sh \
  --continue-on-error \
  --max-retries 3
```

## Troubleshooting

### Issue: "Config file not found"

```bash
# Create the config file first
cp batch_config.example.txt batch_config.txt
nano batch_config.txt
```

### Issue: "No target URL specified"

```bash
# Option 1: Add full URLs in config
internlm/Intern-S1|https://target.com/Intern-S1.git

# Option 2: Use --target-base
./batch_transfer_optimized.sh --target-base https://target.com/models
```

### Issue: "transfer.py not found"

```bash
# Run from the correct directory
cd /home/maoxin/transfer
./batch_transfer_optimized.sh
```

### Issue: Slow transfers even with acceleration

```bash
# Check if Xget is actually being used
grep "Xget acceleration" batch_transfer_*.log

# Try without Xget to compare
./batch_transfer_optimized.sh --no-xget
```

## Advanced Usage

### Custom Target URLs per Model

```txt
# Mix different targets
internlm/Intern-S1|https://gitlab1.com/models/Intern-S1.git
meta-llama/Llama-2-7b|https://gitlab2.com/models/Llama-2-7b.git
openai/gpt2|https://github.com/myorg/gpt2.git
```

### Integration with Other Scripts

```bash
#!/bin/bash
# wrapper.sh

# Generate config dynamically
python3 generate_model_list.py > batch_config.txt

# Run transfer
./batch_transfer_optimized.sh --continue-on-error

# Send notification
if [ $? -eq 0 ]; then
    notify-send "Batch transfer completed successfully"
else
    notify-send "Batch transfer completed with errors"
fi
```

### Parallel Transfers (Advanced)

**Warning**: Only use if you have sufficient bandwidth and disk I/O.

```bash
# Split config into chunks
split -l 5 batch_config.txt config_chunk_

# Run in parallel (max 3 at a time)
for chunk in config_chunk_*; do
    ./batch_transfer_optimized.sh --config "$chunk" &
    
    # Limit to 3 parallel jobs
    while [ $(jobs -r | wc -l) -ge 3 ]; do
        sleep 10
    done
done

wait  # Wait for all to finish
```

## FAQ

**Q: How long does it take?**  
A: With best performance mode (default):
- Small model (<1GB): 1-3 minutes
- Medium model (1-10GB): 5-20 minutes
- Large model (>10GB): 20-60 minutes

**Q: Can I pause and resume?**  
A: No automatic resume. Comment out completed models in config file and re-run.

**Q: Does it use my .env file?**  
A: Yes, credentials from `.env` are automatically used.

**Q: Can I transfer to different platforms?**  
A: Yes, specify different target URLs in config file.

**Q: What if my internet disconnects?**  
A: Failed transfers are automatically retried (default: 2 times).

## See Also

- [README.md](README.md) - Main documentation
- [ACCELERATION_COMPARISON.md](ACCELERATION_COMPARISON.md) - Performance details
- [XGET_GUIDE.md](XGET_GUIDE.md) - Xget acceleration guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Detailed troubleshooting

---

**Last Updated:** December 2025  
**Script Version:** 1.0.0

