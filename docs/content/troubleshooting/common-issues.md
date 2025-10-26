# Troubleshooting Guide

## Overview

This comprehensive troubleshooting guide helps you diagnose and resolve common issues with the Hugo Template Factory. Issues are categorized by type with step-by-step resolution procedures.

## Prerequisites

Before troubleshooting, ensure you have:

- **Debug information**: Run commands with `--debug --verbose` flags
- **System information**: Operating system, Hugo version, Node.js version
- **Error logs**: Complete error messages and stack traces
- **Reproduction steps**: Clear steps to reproduce the issue

## Quick Diagnosis

Use the built-in diagnostic tool for immediate issue identification:

```bash
# Run comprehensive system check
./scripts/diagnostic.js --all

# Check specific component
./scripts/diagnostic.js --component=build-system

# Validate configuration
./scripts/build.sh --validate-only --debug
```

## Error Categories

### CONFIG Errors

Configuration-related issues with Hugo or component settings.

#### Error: "Invalid configuration file"

**Symptoms:**
```
[ERROR] [CONFIG] Configuration file validation failed
❌ Invalid TOML syntax in hugo.toml
```

**Diagnosis:**
```bash
# Validate Hugo configuration
hugo config --source=./templates/your-template

# Check TOML syntax
./scripts/validate.js --config=./templates/your-template/hugo.toml
```

**Resolution:**
1. **Check TOML syntax**:
   ```bash
   # Use a TOML validator
   python3 -c "import tomli; tomli.load(open('hugo.toml', 'rb'))"
   ```

2. **Verify required fields**:
   ```toml
   # hugo.toml - minimum required configuration
   baseURL = "http://localhost:1313"
   title = "Your Site Title"
   theme = "compose"
   ```

3. **Reset to default**:
   ```bash
   # Copy default configuration
   cp templates/default/hugo.toml your-template/
   ```

#### Error: "Component configuration mismatch"

**Symptoms:**
```
[ERROR] [CONFIG] Component quiz-engine version mismatch
Expected: 1.0.0, Found: 0.9.0
```

**Resolution:**
1. **Update component version**:
   ```yaml
   # components.yml
   components:
     - name: quiz-engine
       version: "1.0.0"  # Use latest version
   ```

2. **Check component compatibility**:
   ```bash
   ./scripts/validate.js --components=quiz-engine --version=1.0.0
   ```

### DEPENDENCY Errors

Missing or incompatible dependencies.

#### Error: "Hugo not found"

**Symptoms:**
```
[ERROR] [DEPENDENCY] Hugo not available for build process
Command 'hugo' not found
```

**Diagnosis:**
```bash
# Check Hugo installation
which hugo
hugo version

# Check PATH
echo $PATH
```

**Resolution:**

**Ubuntu/Debian:**
```bash
# Install Hugo Extended
wget -O hugo.deb https://github.com/gohugoio/hugo/releases/download/v0.148.0/hugo_extended_0.148.0_linux-amd64.deb
sudo dpkg -i hugo.deb
```

**macOS:**
```bash
# Install via Homebrew
brew install hugo
```

**Windows:**
```powershell
# Install via Chocolatey
choco install hugo-extended
```

**Verify installation:**
```bash
hugo version
# Should show: hugo v0.148.0+extended
```

#### Error: "Node.js version incompatible"

**Symptoms:**
```
[ERROR] [DEPENDENCY] Node.js version 16.x is not supported
Minimum required version: 18.0.0
```

**Resolution:**

**Using nvm (recommended):**
```bash
# Install Node.js 18
nvm install 18
nvm use 18
nvm alias default 18
```

**Direct installation:**
- Download from [nodejs.org](https://nodejs.org/)
- Install version 18 or higher

**Verify:**
```bash
node --version  # Should show v18.x.x or higher
npm --version   # Should show compatible npm version
```

### BUILD Errors

Hugo build process failures.

#### Error: "Theme not found"

**Symptoms:**
```
[ERROR] [BUILD] Theme 'compose' not found
Available themes: minimal
```

**Diagnosis:**
```bash
# Check available themes
ls -la themes/

# Check git submodules
git submodule status
```

**Resolution:**
1. **Initialize git submodules**:
   ```bash
   git submodule update --init --recursive
   ```

2. **Verify theme structure**:
   ```bash
   ls -la themes/compose/
   # Should contain: layouts/, static/, theme.toml
   ```

3. **Manual theme installation**:
   ```bash
   cd themes/
   git clone https://github.com/info-tech-io/compose.git
   ```

#### Error: "Content processing failed"

**Symptoms:**
```
[ERROR] [BUILD] Hugo build failed
ERROR: failed to process content file
```

**Diagnosis:**
```bash
# Run Hugo with verbose output
hugo --verbose --source=./build-directory

# Check content syntax
./scripts/validate.js --content=./content/
```

**Resolution:**
1. **Check Markdown syntax**:
   ```bash
   # Validate Markdown files
   find content/ -name "*.md" -exec markdown-lint {} \;
   ```

2. **Verify frontmatter**:
   ```yaml
   ---
   title: "Page Title"
   date: 2025-01-01T00:00:00Z
   draft: false
   ---
   ```

3. **Test with minimal content**:
   ```bash
   # Create test content
   echo "---\ntitle: Test\n---\n# Test Page" > content/test.md
   hugo --source=./build-directory
   ```

### IO Errors

File system and permission issues.

#### Error: "Permission denied"

**Symptoms:**
```
[ERROR] [IO] Failed to create directory: /output/path
Permission denied
```

**Resolution:**
1. **Check directory permissions**:
   ```bash
   ls -la /output/path
   ls -la $(dirname /output/path)
   ```

2. **Fix permissions**:
   ```bash
   # Make directory writable
   chmod 755 /output/path

   # Or change ownership
   sudo chown $USER:$USER /output/path
   ```

3. **Use alternative output location**:
   ```bash
   ./scripts/build.sh --output=./local-output
   ```

#### Error: "File not found"

**Symptoms:**
```
[ERROR] [IO] Input file not found: ./content/custom/_index.md
```

**Resolution:**
1. **Verify file path**:
   ```bash
   find . -name "_index.md" -type f
   ```

2. **Check file permissions**:
   ```bash
   ls -la ./content/custom/_index.md
   ```

3. **Create missing files**:
   ```bash
   mkdir -p ./content/custom
   echo "---\ntitle: Custom Section\n---" > ./content/custom/_index.md
   ```

### VALIDATION Errors

Parameter and configuration validation failures.

#### Error: "Invalid template name"

**Symptoms:**
```
[ERROR] [VALIDATION] Template 'nonexistent' not found
Available templates: default, minimal, academic, enterprise
```

**Resolution:**
1. **List available templates**:
   ```bash
   ./scripts/list.js --templates
   ```

2. **Use correct template name**:
   ```bash
   ./scripts/build.sh --template=default  # Use existing template
   ```

3. **Create custom template**:
   ```bash
   cp -r templates/default templates/custom
   ./scripts/build.sh --template=custom
   ```

## System-Specific Issues

### Windows Issues

#### PowerShell Execution Policy

**Error:**
```
cannot be loaded because running scripts is disabled on this system
```

**Resolution:**
```powershell
# Allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Path Issues

**Error:**
```
'hugo' is not recognized as an internal or external command
```

**Resolution:**
1. Add Hugo to PATH:
   ```cmd
   setx PATH "%PATH%;C:\Hugo\bin"
   ```

2. Restart terminal and verify:
   ```cmd
   hugo version
   ```

### macOS Issues

#### Gatekeeper Restrictions

**Error:**
```
"hugo" cannot be opened because the developer cannot be verified
```

**Resolution:**
```bash
# Allow Hugo execution
sudo spctl --master-disable
# Or specifically allow Hugo
sudo xattr -rd com.apple.quarantine /usr/local/bin/hugo
```

### Linux Issues

#### Snap Package Issues

**Error:**
```
hugo: command not found (when installed via snap)
```

**Resolution:**
```bash
# Add snap bin to PATH
echo 'export PATH="/snap/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Performance Issues

### Slow Build Times

**Symptoms:**
- Build takes longer than 5 minutes
- High CPU/memory usage during build

**Diagnosis:**
```bash
# Profile build performance
time ./scripts/build.sh --template=default --verbose

# Check Hugo build stats
hugo --templateMetrics --source=./build-directory
```

**Resolution:**
1. **Use minimal template for development**:
   ```bash
   ./scripts/build.sh --template=minimal
   ```

2. **Enable Hugo caching**:
   ```bash
   export HUGO_CACHEDIR="$HOME/.hugo-cache"
   ```

3. **Optimize content**:
   ```bash
   # Remove large unused files
   find content/ -name "*.jpg" -size +1M
   ```

4. **Disable unnecessary features**:
   ```bash
   ./scripts/build.sh --no-minify --environment=development
   ```

### Memory Issues

**Symptoms:**
```
fatal error: runtime: out of memory
```

**Resolution:**
1. **Increase available memory**:
   ```bash
   # Set Hugo memory limit
   export HUGO_MAXMEMORY=2048
   ```

2. **Process content in batches**:
   ```bash
   # Split large content directories
   mkdir content/batch1 content/batch2
   ```

## Component-Specific Issues

### Quiz Engine Issues

#### Quiz Not Loading

**Symptoms:**
- Quiz questions don't appear
- JavaScript errors in browser console

**Diagnosis:**
```bash
# Check component integration
./scripts/validate.js --components=quiz-engine

# Verify quiz content format
./scripts/validate.js --quiz-content=./content/quiz/
```

**Resolution:**
1. **Check quiz content format**:
   ```yaml
   # content/quiz/example.yml
   title: "Test Quiz"
   questions:
     - question: "Sample question?"
       type: "single-choice"
       options: ["A", "B", "C"]
       correct: 0
   ```

2. **Verify JavaScript loading**:
   ```html
   <!-- Check in browser developer tools -->
   <script src="/js/quiz-engine.js"></script>
   ```

### Analytics Issues

#### Tracking Not Working

**Symptoms:**
- No analytics data
- Console errors about tracking codes

**Resolution:**
1. **Verify tracking configuration**:
   ```yaml
   # components.yml
   components:
     - name: analytics
       config:
         provider: "google"
         tracking_id: "GA-XXXXXXXXX"
   ```

2. **Check privacy settings**:
   ```yaml
   config:
     privacy_compliant: true
     cookie_consent: true
   ```

## Emergency Procedures

### Complete Reset

If all else fails, perform a complete reset:

```bash
# 1. Backup your custom content
cp -r content/ ../content-backup/

# 2. Reset to clean state
git clean -fdx
git reset --hard HEAD

# 3. Reinitialize
git submodule update --init --recursive
npm ci

# 4. Restore content
cp -r ../content-backup/ content/

# 5. Test with minimal configuration
./scripts/build.sh --template=minimal --validate-only
```

### Emergency Contact

For critical issues that block development:

1. **Create detailed issue report**:
   - System information (`./scripts/diagnostic.js --system`)
   - Error logs with `--debug --verbose`
   - Steps to reproduce

2. **Submit GitHub issue**: [hugo-templates/issues](https://github.com/info-tech-io/hugo-templates/issues)

3. **Include diagnostic output**:
   ```bash
   ./scripts/diagnostic.js --all > diagnostic-report.txt
   ```

## Next Steps

- **Prevent future issues**: [Best Practices Guide](../user-guides/best-practices.md)
- **Learn advanced debugging**: [Developer Debugging Guide](../developer-docs/debugging.md)
- **Contribute fixes**: [Contributing Guide](../developer-docs/contributing.md)

## Related Documentation

- [Build System Guide](../user-guides/build-system.md)
- [Component Development](../developer-docs/components.md)
- [GitHub Actions Debugging](../developer-docs/github-actions.md)
- [Performance Optimization](../user-guides/performance.md)