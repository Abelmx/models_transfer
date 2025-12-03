#!/bin/bash
# Example: Staged Transfer Strategies
# This script demonstrates different ways to use --ignore-lfs and --skip-lfs-errors flags

set -e

# ============================================================================
# Configuration
# ============================================================================

SOURCE_REPO="https://huggingface.co/gpt2"
TARGET_BASE="https://target.com/models"

# ============================================================================
# Example 1: Fast text-only transfer
# ============================================================================

echo "=========================================="
echo "Example 1: Transfer only text files"
echo "=========================================="
echo "Use case: Quick preview, no model weights"
echo ""

# This will transfer in ~1 minute (only text files)
python3 transfer.py \
  --source "$SOURCE_REPO" \
  --target "$TARGET_BASE/gpt2-textonly.git" \
  --ignore-lfs

echo "✅ Text-only transfer complete!"
echo "   Repository structure ready for review"
echo "   Model weights NOT included"
echo ""

# ============================================================================
# Example 2: Pointer-only transfer
# ============================================================================

echo "=========================================="
echo "Example 2: Transfer with LFS pointers"
echo "=========================================="
echo "Use case: Share repository structure, defer large file download"
echo ""

# Set environment variable for pointer-only mode
export GIT_LFS_SKIP_SMUDGE=1

# This will transfer Git structure + pointers (no LFS objects)
python3 transfer.py \
  --source "$SOURCE_REPO" \
  --target "$TARGET_BASE/gpt2-pointers.git" \
  --skip-lfs-errors

unset GIT_LFS_SKIP_SMUDGE

echo "✅ Pointer-only transfer complete!"
echo "   Git structure and LFS pointers included"
echo "   LFS objects will be fetched on demand"
echo ""

# ============================================================================
# Example 3: Complete transfer
# ============================================================================

echo "=========================================="
echo "Example 3: Full transfer (default)"
echo "=========================================="
echo "Use case: Complete repository copy with all files"
echo ""

# This will transfer everything (may take longer)
python3 transfer.py \
  --source "$SOURCE_REPO" \
  --target "$TARGET_BASE/gpt2-complete.git"

echo "✅ Complete transfer finished!"
echo "   Full repository copy including model weights"
echo ""

# ============================================================================
# Example 4: Two-stage strategy
# ============================================================================

echo "=========================================="
echo "Example 4: Two-stage transfer"
echo "=========================================="
echo "Use case: Quick initial setup, full sync later"
echo ""

echo "Stage 1: Quick text-only transfer..."
python3 transfer.py \
  --source "$SOURCE_REPO" \
  --target "$TARGET_BASE/gpt2-staged.git" \
  --ignore-lfs

echo ""
echo "✅ Stage 1 complete! Repository accessible for review."
echo ""
echo "Stage 2: Full transfer with model weights..."
python3 transfer.py \
  --source "$SOURCE_REPO" \
  --target "$TARGET_BASE/gpt2-staged.git"

echo "✅ Stage 2 complete! Full repository now available."
echo ""

# ============================================================================
# Example 5: Batch with different strategies
# ============================================================================

echo "=========================================="
echo "Example 5: Batch transfer with stages"
echo "=========================================="
echo ""

# Create a temporary config file
cat > /tmp/batch_stage1.txt << 'EOF'
# Stage 1: Text-only for quick preview
huggingface.co/bert-base-uncased
huggingface.co/distilbert-base-uncased
huggingface.co/roberta-base
EOF

echo "Stage 1: Batch text-only transfer..."
./batch_transfer_optimized.sh \
  --config /tmp/batch_stage1.txt \
  --target-base "$TARGET_BASE" \
  --ignore-lfs \
  --continue-on-error

echo ""
echo "✅ All repositories available for review (text-only)"
echo ""

# Stage 2: Full transfer for selected models
cat > /tmp/batch_stage2.txt << 'EOF'
# Stage 2: Full transfer for important models
huggingface.co/bert-base-uncased
EOF

echo "Stage 2: Full transfer for selected models..."
./batch_transfer_optimized.sh \
  --config /tmp/batch_stage2.txt \
  --target-base "$TARGET_BASE" \
  --delay 60

echo "✅ Selected models fully transferred with weights"
echo ""

# Cleanup
rm -f /tmp/batch_stage1.txt /tmp/batch_stage2.txt

# ============================================================================
# Summary
# ============================================================================

echo "=========================================="
echo "Summary: Transfer Strategy Comparison"
echo "=========================================="
echo ""
echo "Strategy               | Speed  | Size  | Complete"
echo "----------------------|--------|-------|----------"
echo "--ignore-lfs          | ⚡⚡⚡  | ~10MB | Text only"
echo "--skip-lfs-errors     | ⚡⚡   | ~50MB | + Pointers"
echo "Default (full)        | ⚡     | ~500MB| ✅ Full"
echo ""
echo "Choose based on your needs:"
echo "  - Quick preview → --ignore-lfs"
echo "  - Shared LFS backend → --skip-lfs-errors"
echo "  - Production ready → Default (no flags)"
echo ""
echo "📖 See STAGED_TRANSFER_GUIDE.md for details"

