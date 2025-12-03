#!/bin/bash
# Installation and setup script for HF Model Transfer Tool

set -e  # Exit on error

echo "=========================================="
echo "HuggingFace Model Transfer Tool Setup"
echo "=========================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Step 1: Checking prerequisites..."
echo "---"

# Check Git
if command_exists git; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    print_success "Git is installed (version $GIT_VERSION)"
else
    print_error "Git is not installed"
    echo "  Please install Git first:"
    echo "    Ubuntu/Debian: sudo apt-get install git"
    echo "    macOS: brew install git"
    exit 1
fi

# Check Git LFS
if command_exists git-lfs; then
    GIT_LFS_VERSION=$(git lfs version | awk '{print $1}')
    print_success "Git LFS is installed ($GIT_LFS_VERSION)"
    
    # Check if git lfs is initialized
    if git lfs env > /dev/null 2>&1; then
        print_success "Git LFS is initialized"
    else
        print_warning "Git LFS is not initialized, initializing now..."
        git lfs install
        print_success "Git LFS initialized"
    fi
else
    print_error "Git LFS is not installed"
    echo "  Please install Git LFS first:"
    echo "    Ubuntu/Debian: sudo apt-get install git-lfs"
    echo "    macOS: brew install git-lfs"
    echo ""
    echo "  After installation, run: git lfs install"
    exit 1
fi

# Check Python
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    print_success "Python 3 is installed (version $PYTHON_VERSION)"
else
    print_error "Python 3 is not installed"
    echo "  Please install Python 3 first:"
    echo "    Ubuntu/Debian: sudo apt-get install python3 python3-pip"
    echo "    macOS: brew install python3"
    exit 1
fi

# Check pip
if command_exists pip3; then
    print_success "pip3 is installed"
else
    print_error "pip3 is not installed"
    echo "  Please install pip3 first:"
    echo "    Ubuntu/Debian: sudo apt-get install python3-pip"
    echo "    macOS: It should come with python3"
    exit 1
fi

echo ""
echo "Step 2: Installing Python dependencies..."
echo "---"

if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
    print_success "Python dependencies installed"
else
    print_error "requirements.txt not found"
    exit 1
fi

echo ""
echo "Step 2.5: Installing HuggingFace XET (optional, for faster downloads)..."
echo "---"

pip3 install huggingface_hub[hf_transfer] --upgrade > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_success "HuggingFace XET installed"
    
    # Add to bashrc if not already present
    if ! grep -q "HF_HUB_ENABLE_HF_TRANSFER" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# HuggingFace XET acceleration" >> ~/.bashrc
        echo "export HF_HUB_ENABLE_HF_TRANSFER=1" >> ~/.bashrc
        print_success "HF-XET auto-enabled in ~/.bashrc"
    fi
else
    print_warning "HuggingFace XET installation failed (optional feature)"
fi

echo ""
echo "Step 3: Setting up configuration..."
echo "---"

# Create .env from template if it doesn't exist
if [ ! -f ".env" ]; then
    if [ -f "env.template" ]; then
        cp env.template .env
        print_success "Created .env file from template"
        print_warning "Please edit .env file with your credentials"
    else
        print_error "env.template not found"
        exit 1
    fi
else
    print_warning ".env file already exists, skipping creation"
fi

# Make scripts executable
chmod +x transfer.py batch_transfer.sh example_usage.sh install.sh
print_success "Made scripts executable"

echo ""
echo "Step 4: Verifying installation..."
echo "---"

# Test if the tool runs
if python3 transfer.py --help > /dev/null 2>&1; then
    print_success "transfer.py runs successfully"
else
    print_error "transfer.py failed to run"
    exit 1
fi

echo ""
echo "=========================================="
echo "Installation Complete! 🎉"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Configure your credentials:"
echo "   ${YELLOW}nano .env${NC}"
echo ""
echo "2. Add your tokens to .env:"
echo "   HF_TOKEN=your_huggingface_token"
echo "   TARGET_USERNAME=your_target_username"
echo "   TARGET_TOKEN=your_target_token"
echo ""
echo "3. Run your first transfer:"
echo "   ${YELLOW}python3 transfer.py \\${NC}"
echo "   ${YELLOW}  --source https://huggingface.co/model \\${NC}"
echo "   ${YELLOW}  --target https://target-platform.com/model.git${NC}"
echo ""
echo "Quick references:"
echo "  - Quick start guide: ${YELLOW}cat QUICKSTART.md${NC}"
echo "  - Platform guide: ${YELLOW}cat PLATFORM_GUIDE.md${NC}"
echo "  - Example usage: ${YELLOW}./example_usage.sh${NC}"
echo "  - Help: ${YELLOW}python3 transfer.py --help${NC}"
echo ""

