# Batch Transfer Quick Reference Card

## 🚀 Quick Commands

```bash
# Best performance (default)
./batch_transfer_optimized.sh

# With target base URL
./batch_transfer_optimized.sh --target-base https://platform.com/path

# Dry run (preview)
./batch_transfer_optimized.sh --dry-run

# Continue on errors
./batch_transfer_optimized.sh --continue-on-error

# Show help
./batch_transfer_optimized.sh --help
```

## 📝 Config File Format

```txt
# Format 1: Full URLs
internlm/Intern-S1|https://target.com/Intern-S1.git

# Format 2: Model name only (use with --target-base)
internlm/Intern-S1

# Comments start with #
# Empty lines are ignored
```

## ⚡ Performance Modes

| Mode | Command | Speed Boost |
|------|---------|-------------|
| **Best** (default) | Default | **5-15x** ⭐ |
| Xget only | `--no-hf-transfer` | 3-10x |
| HF-Transfer only | `--no-xget` | 3-5x |
| Standard | `--no-xget --no-hf-transfer` | 1x |

## 🎛️ All Options

| Option | Description |
|--------|-------------|
| `--config FILE` | Custom config file |
| `--target-base URL` | Base URL for targets |
| `--mirror` | Mirror all refs |
| `--no-xget` | Disable Xget |
| `--no-hf-transfer` | Disable HF-Transfer |
| `--use-remote-mirror` | GitLab remote mirror |
| `--no-cleanup` | Keep temp files |
| `--continue-on-error` | Don't stop on failures |
| `--max-retries N` | Retry attempts (default: 2) |
| `--delay N` | Seconds between models (avoid rate limits) |
| `--dry-run` | Preview only |
| `--help` | Show help |

## 📊 Exit Codes

- `0` = All successful
- `1` = All failed  
- `2` = Partial success

## 📋 Workflow

```bash
# 1. Setup
cp batch_config.example.txt batch_config.txt
nano batch_config.txt

# 2. Preview
./batch_transfer_optimized.sh --dry-run

# 3. Transfer
./batch_transfer_optimized.sh

# 4. Check log
ls -t batch_transfer_*.log | head -1 | xargs cat
```

## 💡 Tips

1. ✅ Always use `--dry-run` first
2. ✅ Start with small models for testing
3. ✅ Use `--continue-on-error` for large batches
4. ✅ Check log files for details
5. ✅ Default settings give best performance

## 🔗 Full Documentation

See [BATCH_TRANSFER_GUIDE.md](BATCH_TRANSFER_GUIDE.md) for complete guide.

