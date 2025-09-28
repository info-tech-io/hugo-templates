# Installation Guide

## Overview

This comprehensive installation guide covers setting up the Hugo Template Factory Framework on different operating systems and environments.

## System Requirements

### Minimum Requirements

- **Hugo Extended** ≥ 0.148.0
- **Node.js** ≥ 18.0.0
- **Git** ≥ 2.30.0
- **Bash** shell (Linux/macOS) or **Git Bash** (Windows)

### Recommended Requirements

- **Hugo Extended** ≥ 0.148.0 (latest stable)
- **Node.js** ≥ 20.0.0 (LTS version)
- **NPM** ≥ 9.0.0
- **Git** ≥ 2.40.0
- **4GB RAM** (for large sites)
- **2GB free disk space**

### Optional Dependencies

- **Docker** (for containerized builds)
- **BATS** (for bash testing)
- **yamllint** (for YAML validation)

## Quick Installation

### One-Line Installation (Linux/macOS)

```bash
curl -fsSL https://raw.githubusercontent.com/info-tech-io/hugo-templates/main/scripts/install.sh | bash
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/info-tech-io/hugo-templates.git
cd hugo-templates

# Initialize submodules and install dependencies
git submodule update --init --recursive
npm ci

# Verify installation
./scripts/diagnostic.js --all
```

## Platform-Specific Installation

### Ubuntu/Debian

#### 1. Update System
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Install Hugo Extended
```bash
# Method 1: Download official release (recommended)
HUGO_VERSION="0.148.0"
wget -O hugo.deb https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb
sudo dpkg -i hugo.deb

# Method 2: Using snap (alternative)
sudo snap install hugo --channel=extended
```

#### 3. Install Node.js
```bash
# Method 1: Using NodeSource repository (recommended)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Method 2: Using nvm (user-specific)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
```

#### 4. Install Additional Tools
```bash
# Git (if not already installed)
sudo apt install git

# BATS testing framework (optional)
sudo apt install bats

# YAML linter (optional)
sudo apt install yamllint
```

#### 5. Clone and Setup
```bash
git clone https://github.com/info-tech-io/hugo-templates.git
cd hugo-templates
git submodule update --init --recursive
npm ci
```

### CentOS/RHEL/Fedora

#### 1. Install Hugo Extended
```bash
# Fedora
sudo dnf install hugo

# CentOS/RHEL (manual installation)
HUGO_VERSION="0.148.0"
wget https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz
tar -xzf hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz
sudo mv hugo /usr/local/bin/
```

#### 2. Install Node.js
```bash
# Fedora
sudo dnf install nodejs npm

# CentOS/RHEL
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs
```

#### 3. Install Additional Tools
```bash
sudo dnf install git  # Fedora
sudo yum install git  # CentOS/RHEL
```

### macOS

#### 1. Install Homebrew (if not installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install Hugo Extended
```bash
brew install hugo
```

#### 3. Install Node.js
```bash
# Method 1: Using Homebrew
brew install node

# Method 2: Using nvm (recommended for development)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.zshrc  # or ~/.bash_profile
nvm install 20
nvm use 20
```

#### 4. Install Additional Tools
```bash
# Git (usually pre-installed)
brew install git

# BATS testing framework (optional)
brew install bats-core
```

### Windows

#### 1. Install Git Bash
1. Download Git from [git-scm.com](https://git-scm.com/download/win)
2. Install with "Git Bash Here" option enabled
3. Open Git Bash for all following commands

#### 2. Install Hugo Extended

**Method 1: Using Chocolatey (recommended)**
```powershell
# Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Hugo Extended
choco install hugo-extended
```

**Method 2: Manual Installation**
```bash
# Download and extract Hugo
HUGO_VERSION="0.148.0"
curl -L -o hugo.zip https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_windows-amd64.zip
unzip hugo.zip
mkdir -p /c/Hugo/bin
mv hugo.exe /c/Hugo/bin/

# Add to PATH
echo 'export PATH="/c/Hugo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### 3. Install Node.js
1. Download Node.js LTS from [nodejs.org](https://nodejs.org/)
2. Install using the Windows installer
3. Verify installation in Git Bash:
```bash
node --version
npm --version
```

#### 4. PowerShell Execution Policy
```powershell
# Allow script execution (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Docker Installation

#### 1. Create Dockerfile
```dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Hugo Extended
RUN HUGO_VERSION="0.148.0" && \
    wget -O hugo.deb https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb && \
    dpkg -i hugo.deb && \
    rm hugo.deb

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Set working directory
WORKDIR /workspace

# Copy project files
COPY . .

# Install dependencies
RUN git submodule update --init --recursive && \
    npm ci

# Default command
CMD ["./scripts/build.sh", "--help"]
```

#### 2. Build and Run
```bash
# Build Docker image
docker build -t hugo-templates .

# Run container
docker run -it --rm -v $(pwd):/workspace hugo-templates

# Run specific command
docker run --rm -v $(pwd):/workspace hugo-templates ./scripts/build.sh --template=default
```

## Verification

### System Check

```bash
# Check Hugo installation
hugo version
# Expected: hugo v0.148.0+extended

# Check Node.js installation
node --version
# Expected: v18.x.x or higher

npm --version
# Expected: 9.x.x or higher

# Check Git installation
git --version
# Expected: git version 2.30.x or higher
```

### Project Verification

```bash
# Navigate to project directory
cd hugo-templates

# Run comprehensive diagnostic
./scripts/diagnostic.js --all

# Test basic build
./scripts/build.sh --template=minimal --validate-only

# List available resources
./scripts/list.js --all
```

### Expected Output

Successful installation should show:
```
✅ Hugo Extended v0.148.0 detected
✅ Node.js v20.x.x detected
✅ NPM v9.x.x detected
✅ Git v2.40.x detected
✅ Templates loaded: 5 templates
✅ Themes loaded: 1 theme
✅ Components loaded: 1 component
✅ Build system: Ready
```

## Troubleshooting Installation

### Common Issues

#### Hugo Not Found
```bash
# Check if Hugo is in PATH
which hugo

# Check Hugo version
hugo version

# Reinstall if necessary (Ubuntu)
sudo dpkg -r hugo
wget -O hugo.deb https://github.com/gohugoio/hugo/releases/download/v0.148.0/hugo_extended_0.148.0_linux-amd64.deb
sudo dpkg -i hugo.deb
```

#### Node.js Version Issues
```bash
# Check current version
node --version

# Update using nvm
nvm install 20
nvm use 20
nvm alias default 20

# Update using package manager (Ubuntu)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

#### Permission Issues
```bash
# Fix npm permissions
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Fix script permissions
chmod +x scripts/*.sh
```

#### Git Submodule Issues
```bash
# Update submodules
git submodule update --init --recursive

# Force update if stuck
git submodule foreach --recursive git reset --hard
git submodule update --force --recursive
```

### Advanced Troubleshooting

#### Clean Installation
```bash
# Remove existing installation
rm -rf node_modules/
rm -f package-lock.json

# Clean npm cache
npm cache clean --force

# Reinstall dependencies
npm ci
```

#### Debug Mode Installation
```bash
# Enable debug logging
export DEBUG=1

# Run diagnostic with verbose output
./scripts/diagnostic.js --verbose --log-file=install-debug.log

# Check detailed logs
cat install-debug.log
```

## Development Environment Setup

### VS Code Configuration

#### 1. Install Extensions
- Hugo Language and Syntax Support
- YAML
- GitLens
- Markdown All in One

#### 2. Workspace Settings (.vscode/settings.json)
```json
{
  "hugo.server.renderToDisk": true,
  "hugo.server.poll": "300ms",
  "files.associations": {
    "*.toml": "toml",
    "*.yml": "yaml"
  },
  "yaml.schemas": {
    "./schemas/components.schema.json": "components.yml"
  }
}
```

### Git Configuration

```bash
# Configure Git (if not already done)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Configure Git hooks (optional)
git config core.hooksPath .githooks
chmod +x .githooks/*
```

### Shell Configuration

#### Bash Aliases (.bashrc or .bash_profile)
```bash
# Hugo Template Factory aliases
alias htf-build='./scripts/build.sh'
alias htf-list='./scripts/list.js'
alias htf-validate='./scripts/validate.js'
alias htf-diag='./scripts/diagnostic.js'

# Quick commands
alias htf-minimal='./scripts/build.sh --template=minimal'
alias htf-default='./scripts/build.sh --template=default'
alias htf-test='./scripts/build.sh --template=minimal --validate-only'
```

#### Zsh Configuration (.zshrc)
```bash
# Same aliases as above, plus:
autoload -U compinit
compinit

# Add custom completion (if available)
source scripts/completion.zsh 2>/dev/null || true
```

## Update Procedures

### Framework Updates

```bash
# Update framework
git pull origin main
git submodule update --recursive

# Update dependencies
npm ci

# Verify update
./scripts/diagnostic.js --all
```

### Hugo Updates

```bash
# Check current version
hugo version

# Update Hugo (Ubuntu)
HUGO_VERSION="0.149.0"  # New version
wget -O hugo.deb https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb
sudo dpkg -i hugo.deb

# Update Hugo (macOS)
brew upgrade hugo

# Update Hugo (Windows)
choco upgrade hugo-extended
```

### Node.js Updates

```bash
# Update using nvm
nvm install node --latest-npm
nvm use node

# Update global packages
npm update -g
```

## Next Steps

After successful installation:

1. **Read Getting Started**: [Getting Started Tutorial](../tutorials/getting-started.md)
2. **Explore Templates**: [Template Usage Guide](./templates.md)
3. **Try Building**: [Build System Guide](./build-system.md)
4. **Join Community**: [Contributing Guide](../developer-docs/contributing.md)

## Related Documentation

- [Build System Guide](./build-system.md)
- [Template Usage Guide](./templates.md)
- [Troubleshooting Guide](../troubleshooting/common-issues.md)
- [Developer Setup](../developer-docs/contributing.md)