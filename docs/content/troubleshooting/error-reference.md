# Error Reference Guide

## Overview

This comprehensive error reference provides detailed information about all error codes, messages, and their resolutions in the Hugo Template Factory Framework.

## Error Code Categories

### CONFIG Errors (Configuration Issues)

#### CONFIG-001: Invalid Configuration File
```
[ERROR] [CONFIG] Configuration file validation failed
❌ Invalid TOML syntax in hugo.toml
```

**Cause**: TOML syntax errors in Hugo configuration files
**Resolution**: Validate TOML syntax using `hugo config` command
**Documentation**: [Build System Guide](../user-guides/build-system.md#configuration)

#### CONFIG-002: Missing Required Fields
```
[ERROR] [CONFIG] Required configuration field missing: baseURL
```

**Cause**: Essential Hugo configuration fields are missing
**Resolution**: Add required fields to hugo.toml configuration
**Example**:
```toml
baseURL = "http://localhost:1313"
title = "Your Site Title"
theme = "compose"
```

#### CONFIG-003: Component Configuration Mismatch
```
[ERROR] [CONFIG] Component quiz-engine version mismatch
Expected: 1.0.0, Found: 0.9.0
```

**Cause**: Component version incompatibility
**Resolution**: Update component version in components.yml
**Documentation**: [Component Development](../developer-docs/components.md)

### DEPENDENCY Errors (Missing Dependencies)

#### DEPENDENCY-001: Hugo Not Found
```
[ERROR] [DEPENDENCY] Hugo not available for build process
Command 'hugo' not found
```

**Cause**: Hugo not installed or not in PATH
**Resolution**: Install Hugo Extended ≥ 0.148.0
**Installation**: [Installation Guide](../user-guides/installation.md#hugo-installation)

#### DEPENDENCY-002: Node.js Version Incompatible
```
[ERROR] [DEPENDENCY] Node.js version 16.x is not supported
Minimum required version: 18.0.0
```

**Cause**: Outdated Node.js version
**Resolution**: Update to Node.js 18+ using nvm or direct installation
**Commands**:
```bash
nvm install 18
nvm use 18
```

#### DEPENDENCY-003: NPM Packages Missing
```
[ERROR] [DEPENDENCY] Required npm packages not installed
```

**Cause**: Missing Node.js dependencies
**Resolution**: Install dependencies using npm ci
**Commands**:
```bash
npm ci
```

### BUILD Errors (Hugo Build Process)

#### BUILD-001: Theme Not Found
```
[ERROR] [BUILD] Theme 'compose' not found
Available themes: minimal
```

**Cause**: Missing or incorrectly installed Hugo theme
**Resolution**: Initialize git submodules for themes
**Commands**:
```bash
git submodule update --init --recursive
```

#### BUILD-002: Template Not Found
```
[ERROR] [BUILD] Template 'nonexistent' not found
Available templates: default, minimal, academic
```

**Cause**: Invalid template name specified
**Resolution**: Use existing template or create new one
**Commands**:
```bash
./scripts/list.js --templates  # List available templates
```

#### BUILD-003: Content Processing Failed
```
[ERROR] [BUILD] Hugo build failed
ERROR: failed to process content file
```

**Cause**: Invalid Markdown or frontmatter syntax
**Resolution**: Validate content files and fix syntax errors
**Validation**:
```bash
./scripts/validate.js --content=./content/
```

### IO Errors (File System Issues)

#### IO-001: Permission Denied
```
[ERROR] [IO] Failed to create directory: /output/path
Permission denied
```

**Cause**: Insufficient file system permissions
**Resolution**: Fix directory permissions or use alternative location
**Commands**:
```bash
chmod 755 /output/path
# or
./scripts/build.sh --output=./local-output
```

#### IO-002: File Not Found
```
[ERROR] [IO] Input file not found: ./content/custom/_index.md
```

**Cause**: Missing required content files
**Resolution**: Create missing files or fix file paths
**Commands**:
```bash
mkdir -p ./content/custom
echo "---\ntitle: Custom Section\n---" > ./content/custom/_index.md
```

#### IO-003: Disk Space Insufficient
```
[ERROR] [IO] No space left on device
```

**Cause**: Insufficient disk space for build output
**Resolution**: Free disk space or use different output directory
**Commands**:
```bash
df -h  # Check disk usage
du -sh ./output/*  # Check output size
```

### VALIDATION Errors (Parameter Validation)

#### VALIDATION-001: Invalid Template Name
```
[ERROR] [VALIDATION] Template 'nonexistent' not found
Available templates: default, minimal, academic
```

**Cause**: Template name doesn't exist in templates directory
**Resolution**: Use valid template name or create new template
**Commands**:
```bash
./scripts/list.js --templates
```

#### VALIDATION-002: Invalid Component Configuration
```
[ERROR] [VALIDATION] Component configuration invalid
Missing required field: name
```

**Cause**: Malformed components.yml file
**Resolution**: Fix component configuration syntax
**Example**:
```yaml
components:
  - name: quiz-engine
    version: "1.0.0"
    config:
      enabled: true
```

#### VALIDATION-003: Invalid Path
```
[ERROR] [VALIDATION] Output path is not writable: /readonly/path
```

**Cause**: Output path doesn't exist or is read-only
**Resolution**: Use writable directory path
**Commands**:
```bash
mkdir -p ./writable/output
./scripts/build.sh --output=./writable/output
```

## System-Specific Errors

### Windows Errors

#### WIN-001: PowerShell Execution Policy
```
cannot be loaded because running scripts is disabled on this system
```

**Resolution**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### WIN-002: Command Not Found
```
'hugo' is not recognized as an internal or external command
```

**Resolution**:
```cmd
setx PATH "%PATH%;C:\Hugo\bin"
```

### macOS Errors

#### MACOS-001: Gatekeeper Restrictions
```
"hugo" cannot be opened because the developer cannot be verified
```

**Resolution**:
```bash
sudo xattr -rd com.apple.quarantine /usr/local/bin/hugo
```

### Linux Errors

#### LINUX-001: Snap Package Path Issues
```
hugo: command not found (when installed via snap)
```

**Resolution**:
```bash
echo 'export PATH="/snap/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Performance Errors

### PERF-001: Build Timeout
```
[ERROR] [PERF] Build process timed out after 300 seconds
```

**Cause**: Build process taking too long
**Resolution**: Optimize build settings or use minimal template
**Commands**:
```bash
./scripts/build.sh --template=minimal
export HUGO_CACHEDIR="$HOME/.hugo-cache"
```

### PERF-002: Memory Exhaustion
```
fatal error: runtime: out of memory
```

**Cause**: Insufficient memory for large content processing
**Resolution**: Increase memory limit or process in batches
**Commands**:
```bash
export HUGO_MAXMEMORY=2048
```

## Component-Specific Errors

### Quiz Engine Errors

#### QUIZ-001: Invalid Quiz Format
```
[ERROR] [QUIZ] Invalid quiz format in content/quiz/example.yml
```

**Cause**: Malformed quiz content file
**Resolution**: Fix quiz content structure
**Example**:
```yaml
title: "Test Quiz"
questions:
  - question: "Sample question?"
    type: "single-choice"
    options: ["A", "B", "C"]
    correct: 0
```

### Analytics Errors

#### ANALYTICS-001: Missing Tracking ID
```
[ERROR] [ANALYTICS] Google Analytics tracking ID not configured
```

**Cause**: Missing or invalid analytics configuration
**Resolution**: Add tracking ID to components.yml
**Example**:
```yaml
components:
  - name: analytics
    config:
      provider: "google"
      tracking_id: "GA-XXXXXXXXX"
```

## Emergency Procedures

### Critical Error Recovery

When encountering critical errors that prevent normal operation:

1. **Complete Reset**:
```bash
# Backup custom content
cp -r content/ ../content-backup/

# Reset to clean state
git clean -fdx
git reset --hard HEAD
git submodule update --init --recursive
npm ci

# Restore content
cp -r ../content-backup/ content/
```

2. **Diagnostic Report**:
```bash
./scripts/diagnostic.js --verbose > error-report.txt
```

3. **Submit Issue**: Include error-report.txt in GitHub issue

## Error Reporting

When reporting errors, include:

1. **System Information**: OS, Hugo version, Node.js version
2. **Command Used**: Exact command that caused the error
3. **Full Error Output**: Complete error message with stack trace
4. **Diagnostic Output**: Results from `./scripts/diagnostic.js --verbose`
5. **Reproduction Steps**: How to reproduce the error

## Related Documentation

- [Common Issues Guide](./common-issues.md)
- [Interactive Troubleshooting](./interactive-flowchart.md)
- [Build System Guide](../user-guides/build-system.md)
- [Component Development](../developer-docs/components.md)