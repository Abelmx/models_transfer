#!/bin/bash
# Example usage script demonstrating different ways to use the transfer tool

echo "=========================================="
echo "HuggingFace Model Transfer Tool Examples"
echo "=========================================="
echo ""

# Example 1: Basic transfer with .env file
echo "Example 1: Basic transfer using .env configuration"
echo "---"
echo "python3 transfer.py \\"
echo "  --source https://huggingface.co/internlm/Intern-S1 \\"
echo "  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git"
echo ""

# Example 2: Transfer with inline credentials
echo "Example 2: Transfer with credentials in URL"
echo "---"
echo "python3 transfer.py \\"
echo "  --source https://huggingface.co/internlm/Intern-S1 \\"
echo "  --target https://maoxin:glpat-token@nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git"
echo ""

# Example 3: Keep temporary files
echo "Example 3: Keep temporary files for debugging"
echo "---"
echo "python3 transfer.py \\"
echo "  --source https://huggingface.co/internlm/Intern-S1 \\"
echo "  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \\"
echo "  --no-cleanup"
echo ""

# Example 4: Custom .env file
echo "Example 4: Use custom environment file"
echo "---"
echo "python3 transfer.py \\"
echo "  --source https://huggingface.co/internlm/Intern-S1 \\"
echo "  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \\"
echo "  --env-file /path/to/custom.env"
echo ""

# Example 5: Custom temp directory
echo "Example 5: Specify custom temporary directory"
echo "---"
echo "python3 transfer.py \\"
echo "  --source https://huggingface.co/internlm/Intern-S1 \\"
echo "  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \\"
echo "  --temp-dir /tmp/my_transfer"
echo ""

# Example 6: Use Xget acceleration for faster downloads
echo "Example 6: Xget acceleration (3-10x faster HuggingFace downloads)"
echo "---"
echo "python3 transfer.py \\"
echo "  --source https://huggingface.co/internlm/Intern-S1 \\"
echo "  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \\"
echo "  --use-xget"
echo ""

# Example 7: Mirror mode (sync ALL refs)
echo "Example 7: Mirror mode - sync ALL branches, tags, and refs"
echo "---"
echo "python3 transfer.py \\"
echo "  --source https://huggingface.co/internlm/Intern-S1 \\"
echo "  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \\"
echo "  --mirror"
echo ""

# Example 8: Configure GitLab pull mirror (offload transfer)
echo "Example 8: Configure GitLab pull mirror (offload transfer)"
echo "---"
echo "python3 transfer.py \\"
echo "  --source https://huggingface.co/internlm/Intern-S1 \\"
echo "  --target https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git \\"
echo "  --use-remote-mirror"
echo ""

# Example 9: Help
echo "Example 9: Show help message"
echo "---"
echo "python3 transfer.py --help"
echo ""

echo "=========================================="
echo "Quick Start"
echo "=========================================="
echo "1. Copy env.template to .env:"
echo "   cp env.template .env"
echo ""
echo "2. Edit .env with your credentials:"
echo "   nano .env"
echo ""
echo "3. Run the transfer:"
echo "   python transfer.py --source <HF_URL> --target <TARGET_URL>"
echo ""

