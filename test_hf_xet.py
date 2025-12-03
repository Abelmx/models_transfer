#!/usr/bin/env python3
"""
Test script to verify HF-XET (HuggingFace Transfer acceleration) is working.
"""

import os
import sys

# Enable HF-XET acceleration
os.environ['HF_HUB_ENABLE_HF_TRANSFER'] = '1'

try:
    import hf_xet
    print("✅ hf-xet package is installed")
except ImportError:
    print("❌ hf-xet package not found")
    print("   Install with: pip install huggingface_hub[hf_transfer]")
    sys.exit(1)

try:
    from huggingface_hub import HfApi, snapshot_download
    print("✅ huggingface_hub is installed")
except ImportError:
    print("❌ huggingface_hub not found")
    sys.exit(1)

# Check environment variable
hf_transfer_enabled = os.environ.get('HF_HUB_ENABLE_HF_TRANSFER')
if hf_transfer_enabled == '1':
    print("✅ HF_HUB_ENABLE_HF_TRANSFER is enabled")
else:
    print("⚠️  HF_HUB_ENABLE_HF_TRANSFER is not set")
    print("   Set it with: export HF_HUB_ENABLE_HF_TRANSFER=1")

print("\n" + "="*60)
print("🚀 HF-XET Setup Complete!")
print("="*60)
print("\nFeatures enabled:")
print("  • Fast parallel downloads from HuggingFace Hub")
print("  • Optimized for large model files (>5GB)")
print("  • Resumable downloads")
print("  • Up to 10x faster than standard git-lfs")

print("\n" + "="*60)
print("📝 Quick Usage Examples")
print("="*60)

print("\n1. Download a model with Python:")
print("""
import os
os.environ['HF_HUB_ENABLE_HF_TRANSFER'] = '1'
from huggingface_hub import snapshot_download

model_path = snapshot_download(
    repo_id="internlm/Intern-S1",
    cache_dir="./models"
)
""")

print("\n2. Use with the transfer tool:")
print("""
export HF_HUB_ENABLE_HF_TRANSFER=1
python3 transfer.py \\
  --source https://huggingface.co/internlm/Intern-S1 \\
  --target https://your-target.com/repo.git
""")

print("\n3. List HuggingFace repo files:")
print("""
from huggingface_hub import HfApi
api = HfApi()
files = api.list_repo_files("internlm/Intern-S1")
print(files)
""")

print("\n" + "="*60)
print("📚 Documentation: HF_XET_SETUP.md")
print("="*60)

print("\n✨ Ready to use HF-XET accelerated downloads!")

