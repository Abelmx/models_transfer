# 推荐配置（两个都设置）
export HF_HUB_ENABLE_HF_TRANSFER=1  # 为 Python 环境准备

python3 transfer.py \
  --source https://huggingface.co/internlm/Intern-S1-mini \
  --target nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin/Intern-S1.git 