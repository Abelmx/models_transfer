#!/bin/bash
# Batch transfer script for multiple models
# Usage: ./batch_transfer.sh

set -e  # Exit on error

# Define your models here
# Format: "source_url|target_url"
MODELS=(
    "https://huggingface.co/internlm/Intern-S1|https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git"
    # Add more models here:
    # "https://huggingface.co/internlm/internlm2-chat-7b|https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/internlm2-chat-7b.git"
)

echo "=========================================="
echo "Batch Model Transfer"
echo "=========================================="
echo "Total models to transfer: ${#MODELS[@]}"
echo ""

SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_MODELS=()

for i in "${!MODELS[@]}"; do
    IFS='|' read -r SOURCE TARGET <<< "${MODELS[$i]}"
    
    echo ""
    echo "=========================================="
    echo "Processing model $((i+1))/${#MODELS[@]}"
    echo "Source: $SOURCE"
    echo "Target: $TARGET"
    echo "=========================================="
    
    if python3 transfer.py --source "$SOURCE" --target "$TARGET"; then
        echo "✅ Model $((i+1)) transferred successfully"
        ((SUCCESS_COUNT++))
    else
        echo "❌ Model $((i+1)) transfer failed"
        ((FAILED_COUNT++))
        FAILED_MODELS+=("$SOURCE")
    fi
done

echo ""
echo "=========================================="
echo "Batch Transfer Summary"
echo "=========================================="
echo "Total: ${#MODELS[@]}"
echo "Success: $SUCCESS_COUNT"
echo "Failed: $FAILED_COUNT"

if [ $FAILED_COUNT -gt 0 ]; then
    echo ""
    echo "Failed models:"
    for model in "${FAILED_MODELS[@]}"; do
        echo "  - $model"
    done
    exit 1
fi

echo ""
echo "🎉 All models transferred successfully!"

