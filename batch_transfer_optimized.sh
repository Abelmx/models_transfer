#!/bin/bash
# Optimized Batch Transfer Script for HuggingFace Models
# Features:
#   - Best performance by default (Xget + HF-Transfer)
#   - Flexible configuration
#   - Progress tracking
#   - Error handling and retry
#   - Detailed logging

set -e  # Exit on error (can be disabled with --continue-on-error)

# ============================================================================
# Configuration
# ============================================================================

# Default settings - Best performance mode
DEFAULT_USE_XGET=true                    # Enable Xget CDN acceleration
DEFAULT_USE_MIRROR=false                 # Mirror mode (all refs)
DEFAULT_USE_REMOTE_MIRROR=false          # GitLab remote mirroring
DEFAULT_NO_CLEANUP=false                 # Keep temporary files
DEFAULT_CONTINUE_ON_ERROR=false          # Continue on individual failures
DEFAULT_MAX_RETRIES=2                    # Retry failed transfers
DEFAULT_DELAY_BETWEEN_MODELS=0           # Delay in seconds between models (0=no delay)

# Target platform base URL (set this or provide per-model)
DEFAULT_TARGET_BASE_URL=""

# Log file
LOG_FILE="batch_transfer_$(date +%Y%m%d_%H%M%S).log"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Functions
# ============================================================================

print_success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo "" | tee -a "$LOG_FILE"
    echo "============================================================================" | tee -a "$LOG_FILE"
    echo "$1" | tee -a "$LOG_FILE"
    echo "============================================================================" | tee -a "$LOG_FILE"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Batch transfer HuggingFace models with optimal performance settings.

OPTIONS:
    --config FILE           Path to config file (default: batch_config.txt)
    --target-base URL       Base URL for target platform
    --mirror                Enable mirror mode (sync all refs)
    --no-xget               Disable Xget acceleration
    --no-hf-transfer        Disable HF-Transfer acceleration
    --use-remote-mirror     Use GitLab remote mirroring
    --no-cleanup            Keep temporary files
    --continue-on-error     Continue even if some transfers fail
    --max-retries N         Maximum retry attempts (default: 2)
    --delay N               Delay in seconds between models (default: 0, helps avoid rate limits)
    --dry-run               Show what would be transferred without doing it
    --help                  Show this help message

PERFORMANCE MODES:
    Default (Best):         Xget + HF-Transfer enabled (3-15x faster)
    Xget Only:              --no-hf-transfer
    HF-Transfer Only:       --no-xget
    Standard:               --no-xget --no-hf-transfer

EXAMPLES:
    # Use default config file (batch_config.txt)
    $0

    # Use custom config
    $0 --config my_models.txt

    # Set target base URL
    $0 --target-base https://nm.aihuanxin.cn/qdlake/repo/llm_model/maoxin

    # Mirror mode with custom config
    $0 --config models.txt --mirror

    # Dry run to preview
    $0 --dry-run

CONFIG FILE FORMAT:
    # Lines starting with # are comments
    # Format: source_repo|target_repo
    # Or: source_repo  (uses target-base + model name)
    
    internlm/Intern-S1|https://target.com/Intern-S1.git
    meta-llama/Llama-2-7b|https://target.com/Llama-2-7b.git
    
    # Use default target base
    openai/whisper-large

EOF
}

parse_config_line() {
    local line="$1"
    local target_base="$2"
    
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && return 1
    
    # Parse source|target format
    if [[ "$line" =~ \| ]]; then
        SOURCE_URL="https://huggingface.co/$(echo "$line" | cut -d'|' -f1 | xargs)"
        TARGET_URL="$(echo "$line" | cut -d'|' -f2 | xargs)"
    else
        # Single repo name, construct URLs
        REPO_NAME="$(echo "$line" | xargs)"
        SOURCE_URL="https://huggingface.co/$REPO_NAME"
        
        if [[ -n "$target_base" ]]; then
            MODEL_NAME="$(basename "$REPO_NAME")"
            TARGET_URL="$target_base/$MODEL_NAME.git"
        else
            print_error "No target URL specified for $REPO_NAME and no target-base set"
            return 1
        fi
    fi
    
    return 0
}

transfer_model() {
    local source="$1"
    local target="$2"
    local attempt="$3"
    
    print_info "Attempting transfer (attempt $attempt)"
    print_info "  Source: $source"
    print_info "  Target: $target"
    
    # Build command
    local cmd="python3 transfer.py"
    cmd="$cmd --source '$source'"
    cmd="$cmd --target '$target'"
    
    [[ "$USE_XGET" == "true" ]] && cmd="$cmd --use-xget"
    [[ "$USE_MIRROR" == "true" ]] && cmd="$cmd --mirror"
    [[ "$USE_REMOTE_MIRROR" == "true" ]] && cmd="$cmd --use-remote-mirror"
    [[ "$NO_CLEANUP" == "true" ]] && cmd="$cmd --no-cleanup"
    
    # Execute
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  Would execute: $cmd" | tee -a "$LOG_FILE"
        return 0
    else
        echo "  Executing: $cmd" >> "$LOG_FILE"
        if eval "$cmd" >> "$LOG_FILE" 2>&1; then
            return 0
        else
            return 1
        fi
    fi
}

# ============================================================================
# Parse Arguments
# ============================================================================

CONFIG_FILE="batch_config.txt"
USE_XGET="$DEFAULT_USE_XGET"
USE_HF_TRANSFER=true
USE_MIRROR="$DEFAULT_USE_MIRROR"
USE_REMOTE_MIRROR="$DEFAULT_USE_REMOTE_MIRROR"
NO_CLEANUP="$DEFAULT_NO_CLEANUP"
CONTINUE_ON_ERROR="$DEFAULT_CONTINUE_ON_ERROR"
MAX_RETRIES="$DEFAULT_MAX_RETRIES"
DELAY_BETWEEN_MODELS="$DEFAULT_DELAY_BETWEEN_MODELS"
TARGET_BASE_URL="$DEFAULT_TARGET_BASE_URL"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --target-base)
            TARGET_BASE_URL="$2"
            shift 2
            ;;
        --mirror)
            USE_MIRROR=true
            shift
            ;;
        --no-xget)
            USE_XGET=false
            shift
            ;;
        --no-hf-transfer)
            USE_HF_TRANSFER=false
            shift
            ;;
        --use-remote-mirror)
            USE_REMOTE_MIRROR=true
            shift
            ;;
        --no-cleanup)
            NO_CLEANUP=true
            shift
            ;;
        --continue-on-error)
            CONTINUE_ON_ERROR=true
            set +e  # Don't exit on error
            shift
            ;;
        --max-retries)
            MAX_RETRIES="$2"
            shift 2
            ;;
        --delay)
            DELAY_BETWEEN_MODELS="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# ============================================================================
# Main Script
# ============================================================================

print_header "HuggingFace Model Batch Transfer (Optimized)"

# Display configuration
echo "Configuration:" | tee -a "$LOG_FILE"
echo "  Config file:      $CONFIG_FILE" | tee -a "$LOG_FILE"
echo "  Xget accel:       $USE_XGET" | tee -a "$LOG_FILE"
echo "  HF-Transfer:      $USE_HF_TRANSFER" | tee -a "$LOG_FILE"
echo "  Mirror mode:      $USE_MIRROR" | tee -a "$LOG_FILE"
echo "  Remote mirror:    $USE_REMOTE_MIRROR" | tee -a "$LOG_FILE"
echo "  Target base URL:  ${TARGET_BASE_URL:-"(not set)"}" | tee -a "$LOG_FILE"
echo "  Max retries:      $MAX_RETRIES" | tee -a "$LOG_FILE"
echo "  Delay (seconds):  $DELAY_BETWEEN_MODELS" | tee -a "$LOG_FILE"
echo "  Dry run:          $DRY_RUN" | tee -a "$LOG_FILE"
echo "  Log file:         $LOG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    print_error "Config file not found: $CONFIG_FILE"
    echo ""
    echo "Create a config file with format:"
    echo "  source_repo|target_url"
    echo "  or just: source_repo (if using --target-base)"
    echo ""
    echo "Example:"
    echo "  internlm/Intern-S1|https://target.com/Intern-S1.git"
    echo "  meta-llama/Llama-2-7b"
    exit 1
fi

# Enable HF-Transfer if requested
if [[ "$USE_HF_TRANSFER" == "true" ]]; then
    export HF_HUB_ENABLE_HF_TRANSFER=1
    print_info "HF-Transfer acceleration enabled"
else
    unset HF_HUB_ENABLE_HF_TRANSFER
    print_info "HF-Transfer acceleration disabled"
fi

# Check if transfer.py exists
if [[ ! -f "transfer.py" ]]; then
    print_error "transfer.py not found in current directory"
    exit 1
fi

# Parse config file and count models
declare -a MODELS
while IFS= read -r line || [[ -n "$line" ]]; do
    if parse_config_line "$line" "$TARGET_BASE_URL"; then
        MODELS+=("$SOURCE_URL|$TARGET_URL")
    fi
done < "$CONFIG_FILE"

TOTAL_MODELS=${#MODELS[@]}

if [[ $TOTAL_MODELS -eq 0 ]]; then
    print_error "No valid models found in config file"
    exit 1
fi

print_info "Found $TOTAL_MODELS model(s) to transfer"
echo "" | tee -a "$LOG_FILE"

# Process each model
SUCCESS_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0
declare -a FAILED_MODELS

for i in "${!MODELS[@]}"; do
    IFS='|' read -r SOURCE TARGET <<< "${MODELS[$i]}"
    
    MODEL_NUM=$((i + 1))
    
    print_header "Model $MODEL_NUM/$TOTAL_MODELS"
    
    # Try transfer with retries
    RETRY_COUNT=0
    TRANSFER_SUCCESS=false
    
    while [[ $RETRY_COUNT -le $MAX_RETRIES ]]; do
        if transfer_model "$SOURCE" "$TARGET" $((RETRY_COUNT + 1)); then
            TRANSFER_SUCCESS=true
            break
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [[ $RETRY_COUNT -le $MAX_RETRIES ]]; then
                print_warning "Transfer failed, retrying ($RETRY_COUNT/$MAX_RETRIES)..."
                sleep 5
            fi
        fi
    done
    
    # Record result
    if [[ "$TRANSFER_SUCCESS" == "true" ]]; then
        print_success "Model $MODEL_NUM transferred successfully"
        ((SUCCESS_COUNT++))
    else
        print_error "Model $MODEL_NUM transfer failed after $((RETRY_COUNT)) attempts"
        ((FAILED_COUNT++))
        FAILED_MODELS+=("$SOURCE")
        
        if [[ "$CONTINUE_ON_ERROR" != "true" ]]; then
            print_error "Stopping due to failure (use --continue-on-error to continue)"
            break
        fi
    fi
    
    # Add delay between models (if configured and not last model)
    if [[ $DELAY_BETWEEN_MODELS -gt 0 && $MODEL_NUM -lt $TOTAL_MODELS ]]; then
        print_info "Waiting ${DELAY_BETWEEN_MODELS}s before next model (avoid rate limits)..."
        sleep "$DELAY_BETWEEN_MODELS"
    fi
    
    echo "" | tee -a "$LOG_FILE"
done

# ============================================================================
# Summary
# ============================================================================

print_header "Transfer Summary"

echo "Total models:     $TOTAL_MODELS" | tee -a "$LOG_FILE"
echo "Successful:       $SUCCESS_COUNT" | tee -a "$LOG_FILE"
echo "Failed:           $FAILED_COUNT" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [[ $FAILED_COUNT -gt 0 ]]; then
    echo "Failed models:" | tee -a "$LOG_FILE"
    for model in "${FAILED_MODELS[@]}"; do
        echo "  - $model" | tee -a "$LOG_FILE"
    done
    echo "" | tee -a "$LOG_FILE"
fi

# Performance stats
if [[ "$DRY_RUN" != "true" ]]; then
    echo "Performance settings used:" | tee -a "$LOG_FILE"
    echo "  Xget acceleration:    $USE_XGET" | tee -a "$LOG_FILE"
    echo "  HF-Transfer:          $USE_HF_TRANSFER" | tee -a "$LOG_FILE"
    if [[ "$USE_XGET" == "true" && "$USE_HF_TRANSFER" == "true" ]]; then
        echo "  Mode: BEST PERFORMANCE (5-15x faster)" | tee -a "$LOG_FILE"
    elif [[ "$USE_XGET" == "true" ]]; then
        echo "  Mode: Xget Only (3-10x faster)" | tee -a "$LOG_FILE"
    elif [[ "$USE_HF_TRANSFER" == "true" ]]; then
        echo "  Mode: HF-Transfer Only (3-5x faster)" | tee -a "$LOG_FILE"
    else
        echo "  Mode: Standard (baseline)" | tee -a "$LOG_FILE"
    fi
fi

echo "" | tee -a "$LOG_FILE"
echo "Detailed log: $LOG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Exit with appropriate code
if [[ $FAILED_COUNT -gt 0 ]]; then
    if [[ $SUCCESS_COUNT -eq 0 ]]; then
        print_error "All transfers failed!"
        exit 1
    else
        print_warning "Some transfers failed"
        exit 2
    fi
else
    print_success "All transfers completed successfully! 🎉"
    exit 0
fi

