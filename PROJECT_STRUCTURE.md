# Project Structure

```
transfer/
├── transfer.py              # Main CLI tool (core functionality)
├── requirements.txt         # Python dependencies
├── env.template            # Environment variables template
├── .gitignore              # Git ignore rules
│
├── README.md               # Main documentation
├── QUICKSTART.md           # Quick start guide (5-minute setup)
├── PLATFORM_GUIDE.md       # Platform-specific configuration guide
├── PROJECT_STRUCTURE.md    # This file
│
├── batch_transfer.sh       # Script for batch transfers
└── example_usage.sh        # Example commands and usage patterns
```

## File Descriptions

### Core Files

#### `transfer.py`
The main Python CLI tool that handles the entire transfer process.

**Key Features:**
- Clones from HuggingFace
- Fetches Git LFS files
- Changes remote to target platform
- Pushes to target platform
- Automatic cleanup
- Configures GitLab pull mirrors when `--use-remote-mirror` is specified (no local data transfer)

**Main Class:** `ModelTransfer`

**Functions:**
- `MirrorManager` – sets up GitLab pull mirrors via API
- `clone_source()` - Clone from HuggingFace
- `fetch_lfs_files()` - Download LFS files
- `change_remote()` - Switch git remote
- `push_to_target()` - Push to target platform
- `cleanup()` - Remove temporary files
- `transfer()` - Execute full transfer pipeline

#### `requirements.txt`
Python package dependencies.

**Current Dependencies:**
- `python-dotenv>=1.0.0` - For loading .env files

#### `env.template`
Template for environment variables configuration.

**Variables:**
- `HF_TOKEN` - HuggingFace access token
- `HF_USERNAME` - HuggingFace username (optional)
- `TARGET_USERNAME` - Target platform username
- `TARGET_TOKEN` - Target platform access token

**Usage:**
```bash
cp env.template .env
nano .env  # Edit with your credentials
```

#### `.gitignore`
Prevents sensitive files from being committed.

**Ignores:**
- `.env` files (contains secrets)
- Python cache files
- Temporary directories
- IDE files

### Documentation Files

#### `README.md`
Comprehensive documentation covering:
- Installation instructions
- Configuration guide
- Usage examples
- Troubleshooting
- Supported platforms
- Security notes

**Target Audience:** All users

#### `QUICKSTART.md`
Fast-track guide to get started in 5 minutes.

**Contains:**
- Prerequisites check
- Step-by-step setup
- Common scenarios
- Quick troubleshooting

**Target Audience:** New users who want to start quickly

#### `PLATFORM_GUIDE.md`
Platform-specific configuration details.

**Covers:**
- HuggingFace
- OpenXlab
- ModelScope
- GitLab (self-hosted)
- Custom platforms

**Contains:**
- Token generation instructions
- URL format examples
- Complete configuration examples
- Platform-specific troubleshooting

**Target Audience:** Users working with specific platforms

#### `PROJECT_STRUCTURE.md`
This file - explains the project organization.

**Target Audience:** Developers and contributors

### Utility Scripts

#### `batch_transfer.sh`
Bash script for transferring multiple models in one go.

**Features:**
- Process multiple models sequentially
- Success/failure tracking
- Summary report
- Error handling

**Usage:**
```bash
# Edit the script to add your models
nano batch_transfer.sh

# Run batch transfer
./batch_transfer.sh
```

**Example Configuration:**
```bash
MODELS=(
    "https://huggingface.co/model1|https://target.com/model1.git"
    "https://huggingface.co/model2|https://target.com/model2.git"
)
```

#### `example_usage.sh`
Displays example commands for different use cases.

**Contains:**
- Basic transfer example
- Transfer with inline credentials
- Keep temporary files
- Custom .env file
- Custom temp directory
- Help command

**Usage:**
```bash
./example_usage.sh
```

## Workflow

```
User
  │
  ├─→ Reads QUICKSTART.md (Quick setup)
  │
  ├─→ Copies env.template to .env
  │
  ├─→ Edits .env with credentials
  │
  ├─→ Runs transfer.py
  │     │
  │     ├─→ Loads .env (via python-dotenv)
  │     │
  │     ├─→ Validates git-lfs installation
  │     │
  │     ├─→ Creates ModelTransfer instance
  │     │
  │     └─→ Executes transfer pipeline:
  │           ├─→ clone_source()
  │           ├─→ fetch_lfs_files()
  │           ├─→ change_remote()
  │           ├─→ push_to_target()
  │           └─→ cleanup()
  │
  └─→ Success! Model transferred
```

## Data Flow

```
HuggingFace Repository
         │
         │ (git clone)
         ↓
  Temporary Directory
    /tmp/hf_transfer_*/
         │
         │ (git lfs fetch)
         │ (git lfs checkout)
         ↓
  Local Repository
  (with LFS files)
         │
         │ (git remote change)
         │ (git push)
         ↓
  Target Platform Repository
```

## Security Considerations

### Sensitive Files
- `.env` - **NEVER commit** - Contains access tokens
- Temporary directories - May contain auth info in git config

### Protected by .gitignore
- `.env`
- `__pycache__/`
- `*.pyc`
- Temporary directories

### Best Practices
1. Use `.env` for credentials (not inline in commands)
2. Use tokens with minimum required permissions
3. Rotate tokens regularly
4. Never share `.env` file
5. Use `--no-cleanup` only for debugging

## Extension Points

### Adding New Platforms

To add support for a new platform:

1. **Update `PLATFORM_GUIDE.md`:**
   - Add platform-specific section
   - Document token generation process
   - Provide URL format examples

2. **Test with `transfer.py`:**
   - No code changes needed (generic git operations)
   - Just configure `.env` appropriately

3. **Add examples to `example_usage.sh`:**
   ```bash
   echo "Example: Transfer to NewPlatform"
   echo "python3 transfer.py \\"
   echo "  --source https://huggingface.co/model \\"
   echo "  --target https://newplatform.com/model.git"
   ```

### Adding New Features

Common feature additions:

1. **Selective Branch Transfer:**
   - Modify `push_to_target()` method
   - Add `--branches` CLI argument

2. **Progress Indicators:**
   - Use `tqdm` library
   - Wrap git commands with progress tracking

3. **Parallel Transfers:**
   - Use Python's `multiprocessing`
   - Modify `batch_transfer.sh` to use GNU parallel

4. **Resume Capability:**
   - Store transfer state
   - Check state before each step
   - Skip completed steps

## Development Guide

### Setting Up Development Environment

```bash
# Clone repository
cd /home/maoxin/transfer

# Install dependencies
pip install -r requirements.txt

# Install development tools (optional)
pip install black flake8 pylint

# Make scripts executable
chmod +x transfer.py batch_transfer.sh example_usage.sh
```

### Testing

```bash
# Test help output
python3 transfer.py --help

# Test with dry-run (use --no-cleanup to inspect)
python3 transfer.py \
  --source https://huggingface.co/small-model \
  --target https://your-test-repo.git \
  --no-cleanup

# Inspect temporary files
ls -la /tmp/hf_transfer_*/
```

### Code Style

- Follow PEP 8 guidelines
- Use type hints where possible
- Document functions with docstrings
- Keep functions focused and small

## Maintenance

### Regular Tasks

1. **Update Dependencies:**
   ```bash
   pip list --outdated
   pip install --upgrade python-dotenv
   ```

2. **Test with Latest Git LFS:**
   ```bash
   git lfs version
   # Update if needed
   ```

3. **Review Platform Guides:**
   - Check if platforms changed their API
   - Update token generation instructions
   - Update URL formats if changed

### Troubleshooting Common Issues

See README.md and PLATFORM_GUIDE.md for detailed troubleshooting guides.

## Support

For issues or questions:

1. Check `README.md` for general documentation
2. Check `QUICKSTART.md` for setup issues
3. Check `PLATFORM_GUIDE.md` for platform-specific issues
4. Run with `--no-cleanup` to debug
5. Check git/git-lfs installation

## License

This tool is provided as-is for transferring model repositories. Ensure compliance with model licenses when transferring.

---

**Last Updated:** December 2025
**Version:** 1.0.0

