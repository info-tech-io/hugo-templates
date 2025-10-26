# Stage 2: User Guides Enhancement

**Child Issue**: #21 - Documentation & Migration
**Stage**: 2 of 4
**Priority**: HIGH
**Estimated Duration**: 3 hours
**Dependencies**: Stage 1 complete

---

## 🎯 Objective

Enhance existing user guide and create comprehensive tutorials for simple and advanced federation scenarios.

---

## 📋 Tasks Breakdown

### Task 2.1: Review & Enhance federated-builds.md (1 hour)

**Goal**: Enhance existing 412-line user guide without duplication

**Current Content** (already exists):
- ✅ Overview
- ✅ Configuration file structure
- ✅ JSON Schema validation
- ✅ Federation configuration (required/optional fields)
- ✅ Module configuration
- ✅ IDE integration
- ✅ Validation commands
- ✅ Common validation errors
- ✅ Examples (basic)
- ✅ Testing configuration
- ✅ CI/CD integration
- ✅ Best practices
- ✅ Troubleshooting

**Missing Content** (to add):

#### 2.1.1: Command-Line Reference (20 min)
Add comprehensive CLI reference for `federated-build.sh`:

```markdown
## Command-Line Reference

### Basic Usage
\`\`\`bash
./scripts/federated-build.sh --config=modules.json --output=site
\`\`\`

### All Options

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `--config=FILE` | Path to modules.json | Required | `--config=federation.json` |
| `--output=DIR` | Output directory | `./output` | `--output=production` |
| `--dry-run` | Test without building | Off | `--dry-run` |
| `--verbose` | Verbose logging | Off | `--verbose` |
| `--quiet` | Minimal output | Off | `--quiet` |
| `--strategy=TYPE` | Override merge strategy | From config | `--strategy=download-merge-deploy` |
| `--fail-fast` | Stop on first error | Off | `--fail-fast` |

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `TEMP_DIR` | Temporary directory for builds | `TEMP_DIR=/tmp/builds` |
| `NODE_PATH` | Path to Node.js | `NODE_PATH=/usr/bin/node` |
| `DEBUG` | Enable debug output | `DEBUG=1` |

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Configuration error |
| 2 | Validation error |
| 3 | Build error |
| 4 | Merge error |
\`\`\`
```

#### 2.1.2: Error Handling Section (15 min)
Add error handling and debugging guide:

```markdown
## Error Handling

### Common Errors and Solutions

**Error: "Configuration file not found"**
- **Cause**: Invalid path to modules.json
- **Solution**: Check file path, use absolute path if needed
- **Example**: `--config=$(pwd)/modules.json`

**Error: "Module download failed"**
- **Cause**: Invalid repository URL or network issue
- **Solution**: Verify repository URL, check network connectivity
- **Debug**: Use `--verbose` to see detailed error

**Error: "Merge conflict detected"**
- **Cause**: Files with same name in multiple modules
- **Solution**: Use conflict resolution strategy in config
- **Example**: Set `"merge_strategy": "keep-both"` in module config

### Debug Mode

Enable verbose logging to troubleshoot issues:
\`\`\`bash
DEBUG=1 ./scripts/federated-build.sh --config=modules.json --verbose
\`\`\`
```

#### 2.1.3: Performance Tips (15 min)
Add performance optimization section:

```markdown
## Performance Optimization

### Build Performance

**Use Dry-Run for Testing**:
\`\`\`bash
# Test configuration without actual builds (10x faster)
./scripts/federated-build.sh --config=modules.json --dry-run
\`\`\`

**Parallel Module Processing**:
- Federation automatically processes modules in parallel when possible
- Performance: ~1.2s for 5 modules (dry-run)
- See [Performance Benchmarks](../developer-docs/testing/federation-benchmarks.md)

**Cache Hugo Builds**:
- Layer 1 (build.sh) uses Hugo's built-in caching
- Subsequent builds are faster

### Configuration Tips

**Minimize Module Count**:
- Fewer modules = faster builds
- Combine related content when possible

**Optimize Module Size**:
- Smaller modules = faster downloads
- Keep modules focused on specific content

**Use Local Repositories During Development**:
\`\`\`json
{
  "source": {
    "repository": "local",
    "local_path": "/path/to/local/repo"
  }
}
\`\`\`
```

#### 2.1.4: What's New Section (10 min)
Add recent updates section at top of file:

```markdown
## What's New

**Latest Updates** (2025-10-19):
- ✅ Complete test coverage (140 tests, 100% passing)
- ✅ Performance benchmarks (all targets exceeded by 4-46x)
- ✅ Local repository support
- ✅ Enhanced error handling
- ✅ Improved conflict resolution

**Key Features**:
- 🚀 Multi-module federation
- 🔄 Intelligent merge strategies
- 🎨 Automatic CSS path rewriting
- ✅ JSON Schema validation
- 🧪 Comprehensive testing
- 📊 Performance monitoring
```

**File**: `docs/content/user-guides/federated-builds.md` (UPDATE)
**Lines Added**: ~100 lines

---

### Task 2.2: Create Simple Tutorial (1 hour)

**Goal**: Step-by-step guide for 2-module federation

**File**: `docs/content/tutorials/federation-simple-tutorial.md` (NEW)

**Content Structure**:

```markdown
---
title: "Simple Federation Tutorial: 2-Module Setup"
description: "Step-by-step guide to create your first federated build"
weight: 10
---

# Simple Federation Tutorial

Learn to create a federated build with 2 modules in 15 minutes.

## Prerequisites

- Hugo installed
- Node.js installed
- Basic understanding of Hugo sites

## Overview

**What we'll build**:
- Module 1: Main documentation
- Module 2: API reference
- Output: Single unified site

**Time required**: 15 minutes

---

## Step 1: Prepare Module Content (5 min)

### Module 1: Main Docs

Create main documentation module:
\`\`\`bash
mkdir -p modules/main-docs/content
cat > modules/main-docs/content/_index.md << 'EOF'
---
title: "Documentation Home"
---

# Welcome to Our Documentation

This is the main documentation module.
EOF

cat > modules/main-docs/module.json << 'EOF'
{
  "hugo_config": {
    "template": "minimal",
    "theme": "compose"
  }
}
EOF
\`\`\`

### Module 2: API Reference

Create API reference module:
\`\`\`bash
mkdir -p modules/api-docs/content
cat > modules/api-docs/content/_index.md << 'EOF'
---
title: "API Reference"
---

# API Documentation

Complete API reference documentation.
EOF

cat > modules/api-docs/module.json << 'EOF'
{
  "hugo_config": {
    "template": "minimal",
    "theme": "compose"
  }
}
EOF
\`\`\`

---

## Step 2: Create Federation Configuration (5 min)

Create `modules.json` in project root:

\`\`\`json
{
  "$schema": "./schemas/modules.schema.json",
  "federation": {
    "name": "simple-docs-federation",
    "baseURL": "http://localhost:1313",
    "strategy": "download-merge-deploy"
  },
  "modules": [
    {
      "name": "main-docs",
      "source": {
        "repository": "local",
        "local_path": "./modules/main-docs",
        "path": ".",
        "branch": "main"
      },
      "destination": "/",
      "module_json": "module.json"
    },
    {
      "name": "api-docs",
      "source": {
        "repository": "local",
        "local_path": "./modules/api-docs",
        "path": ".",
        "branch": "main"
      },
      "destination": "/api/",
      "module_json": "module.json"
    }
  ]
}
\`\`\`

---

## Step 3: Validate Configuration (2 min)

Validate before building:

\`\`\`bash
# Check JSON syntax
node scripts/validate.js modules.json schemas/modules.schema.json

# Expected output: ✅ Validation successful
\`\`\`

---

## Step 4: Test with Dry-Run (1 min)

Test configuration without building:

\`\`\`bash
./scripts/federated-build.sh --config=modules.json --dry-run

# Expected output:
# Processing module: main-docs ✅
# Processing module: api-docs ✅
# Federation build: DRY-RUN MODE ✅
\`\`\`

---

## Step 5: Build Federated Site (2 min)

Run actual build:

\`\`\`bash
./scripts/federated-build.sh --config=modules.json --output=my-site

# Expected output:
# Downloading modules... ✅
# Merging content... ✅
# Building site... ✅
# Federation build complete! ✅
\`\`\`

---

## Step 6: Verify Output

Check merged site structure:

\`\`\`bash
ls -R my-site/public/

# Expected structure:
# my-site/public/
# ├── index.html          # From main-docs
# └── api/
#     └── index.html      # From api-docs
\`\`\`

Preview the site:
\`\`\`bash
cd my-site
hugo server
# Open http://localhost:1313
\`\`\`

---

## Troubleshooting

**Issue: "Module not found"**
- Check local_path is correct
- Use absolute paths if needed

**Issue: "Build failed"**
- Run with --verbose for details
- Check module.json is valid

**Issue: "Merge conflict"**
- Both modules have same file
- Use different destination paths

---

## Next Steps

- [Advanced Tutorial](./federation-advanced-tutorial.md) - 5-module production setup
- [User Guide](../user-guides/federated-builds.md) - Complete reference
- [Migration Checklist](./federation-migration-checklist.md) - Migrate existing site

---

**Estimated Completion Time**: 15 minutes
**Difficulty**: Beginner
**Last Updated**: 2025-10-19
```

**Estimated Lines**: ~150 lines

---

### Task 2.3: Create Advanced Tutorial (1 hour)

**Goal**: Step-by-step guide for 5-module InfoTech.io production scenario

**File**: `docs/content/tutorials/federation-advanced-tutorial.md` (NEW)

**Content Structure**:

```markdown
---
title: "Advanced Federation Tutorial: 5-Module Production"
description: "Production-grade federated build with InfoTech.io example"
weight: 20
---

# Advanced Federation Tutorial

Build a production-ready federated site with 5 modules (InfoTech.io example).

## Prerequisites

- Completed [Simple Tutorial](./federation-simple-tutorial.md)
- Understanding of Hugo modules
- Git repositories ready

## Overview

**What we'll build**: InfoTech.io Documentation
- Module 1: Main documentation (root)
- Module 2: Data Science tutorials (/datascience/)
- Module 3: Machine Learning guides (/ml/)
- Module 4: AI Lab documentation (/ai-lab/)
- Module 5: InfoSec Security guides (/infosec/)

**Time required**: 45 minutes

---

## Step 1: Review InfoTech.io Configuration (10 min)

Review the production configuration:

\`\`\`bash
cat docs/content/examples/modules-infotech.json
\`\`\`

**Key Features**:
- 5 separate modules
- Different destination paths
- CSS path rewriting enabled
- Merge strategy: download-merge-deploy
- Production baseURL

---

## Step 2: Understand Module Structure (10 min)

### Module Organization

Each module has independent structure:

\`\`\`
infotech-main/
└── content/
    ├── _index.md
    ├── about/
    └── module.json

datascience-tutorials/
└── content/
    ├── _index.md
    ├── python/
    ├── r/
    └── module.json
\`\`\`

### Module Independence

Each team works independently:
- Separate Git repositories
- Independent CI/CD
- Own build configuration
- Team-specific content

---

## Step 3: Handle CSS Path Resolution (10 min)

### Why CSS Path Rewriting?

When modules are deployed to subdirectories:
- Original: `/css/style.css`
- Federated: `/datascience/css/style.css`

### Configuration

Enable in modules.json:
\`\`\`json
{
  "name": "datascience",
  "css_path_prefix": "/datascience"
}
\`\`\`

### Verification

Check CSS paths after build:
\`\`\`bash
# Check rewritten paths
grep -r 'href="/datascience/css/' output/public/datascience/

# Verify no absolute paths remaining
grep -r 'href="/css/' output/public/datascience/ || echo "✅ All paths rewritten"
\`\`\`

---

## Step 4: Test Merge Strategy (5 min)

### Download-Merge-Deploy Strategy

\`\`\`bash
# Test with dry-run first
./scripts/federated-build.sh \
  --config=docs/content/examples/modules-infotech.json \
  --dry-run

# Expected: All 5 modules processed
\`\`\`

### Verify Module Destinations

Check destination mapping:
- Module 1 → `/` (root)
- Module 2 → `/datascience/`
- Module 3 → `/ml/`
- Module 4 → `/ai-lab/`
- Module 5 → `/infosec/`

---

## Step 5: Production Build (5 min)

### Build for Production

\`\`\`bash
./scripts/federated-build.sh \
  --config=docs/content/examples/modules-infotech.json \
  --output=infotech-production

# With verbose output
./scripts/federated-build.sh \
  --config=docs/content/examples/modules-infotech.json \
  --output=infotech-production \
  --verbose
\`\`\`

### Monitor Performance

Check build time:
\`\`\`bash
time ./scripts/federated-build.sh \
  --config=docs/content/examples/modules-infotech.json \
  --output=infotech-production

# Expected: ~1.3 seconds (dry-run)
# Production: ~30-60 seconds (with Hugo builds)
\`\`\`

---

## Step 6: Verify Production Output (5 min)

### Check Site Structure

\`\`\`bash
tree -L 2 infotech-production/public/

# Expected structure:
# infotech-production/public/
# ├── index.html                 # Main docs
# ├── datascience/
# │   └── index.html            # DS tutorials
# ├── ml/
# │   └── index.html            # ML guides
# ├── ai-lab/
# │   └── index.html            # AI Lab docs
# └── infosec/
#     └── index.html            # InfoSec guides
\`\`\`

### Validate Navigation

Test navigation between modules:
\`\`\`bash
# Start local server
cd infotech-production
hugo server -p 8080

# Test URLs:
# http://localhost:8080/                # Main
# http://localhost:8080/datascience/   # DS
# http://localhost:8080/ml/            # ML
# http://localhost:8080/ai-lab/        # AI Lab
# http://localhost:8080/infosec/       # InfoSec
\`\`\`

---

## Advanced Topics

### Handling Merge Conflicts

If modules have overlapping files:

\`\`\`json
{
  "merge_strategy": "keep-both",
  "conflict_resolution": {
    "strategy": "rename",
    "pattern": "{module}-{filename}"
  }
}
\`\`\`

### Custom Merge Strategies

Available strategies:
- `download-merge-deploy`: Download all, merge, build once
- `merge-and-build`: Merge first, then build
- `preserve-base-site`: Keep base site, add modules

### Performance Optimization

For large federations:
\`\`\`bash
# Use parallel processing (automatic)
# Enable caching (automatic)
# Monitor with --verbose
\`\`\`

---

## Production Deployment

### GitHub Pages Deployment

\`\`\`yaml
# .github/workflows/deploy.yml
name: Deploy Federation
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Federation
        run: |
          ./scripts/federated-build.sh \
            --config=modules.json \
            --output=public
      - name: Deploy to Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
\`\`\`

---

## Troubleshooting

### Common Issues

**CSS Not Loading**:
- Check css_path_prefix in config
- Verify paths were rewritten
- Use browser DevTools to debug

**Module Not Found**:
- Check repository URL
- Verify branch name
- Test repository access

**Merge Conflicts**:
- Review conflicting files
- Choose appropriate merge strategy
- Use different destination paths

### Debug Mode

\`\`\`bash
DEBUG=1 ./scripts/federated-build.sh \
  --config=modules.json \
  --verbose 2>&1 | tee build.log
\`\`\`

---

## Next Steps

- [Federation Architecture](../developer-docs/federation-architecture.md) - Technical details
- [API Reference](../developer-docs/federation-api-reference.md) - Function docs
- [Performance Benchmarks](../developer-docs/testing/federation-benchmarks.md) - Performance data

---

**Estimated Completion Time**: 45 minutes
**Difficulty**: Advanced
**Last Updated**: 2025-10-19
```

**Estimated Lines**: ~250 lines

---

## 📁 Files Modified/Created

### Files to Update (1 file)
1. `docs/content/user-guides/federated-builds.md`
   - Add command-line reference
   - Add error handling section
   - Add performance tips
   - Add what's new section
   - **Lines Added**: ~100 lines

### Files to Create (2 files)
1. `docs/content/tutorials/federation-simple-tutorial.md`
   - Complete beginner tutorial
   - **Lines**: ~150 lines

2. `docs/content/tutorials/federation-advanced-tutorial.md`
   - Production scenario tutorial
   - **Lines**: ~250 lines

**Total New Content**: ~500 lines (100 updated + 400 new)

---

## ✅ Success Criteria

- [ ] federated-builds.md has CLI reference
- [ ] federated-builds.md has error handling section
- [ ] federated-builds.md has performance tips
- [ ] Simple tutorial complete and tested
- [ ] Advanced tutorial complete and tested
- [ ] All code examples work
- [ ] All JSON references are valid
- [ ] Navigation between docs is clear
- [ ] Tutorials reference correct example files

---

## 🧪 Validation Commands

### Verify File Updates
```bash
# Check federated-builds.md was enhanced
wc -l docs/content/user-guides/federated-builds.md
# Should be ~512 lines (412 + 100)

# Verify new tutorials exist
ls docs/content/tutorials/federation-*.md
# Should show 2 files
```

### Validate JSON References
```bash
# Check simple tutorial references
grep "modules-simple.json" docs/content/tutorials/federation-simple-tutorial.md

# Check advanced tutorial references
grep "modules-infotech.json" docs/content/tutorials/federation-advanced-tutorial.md
```

### Test Code Examples
```bash
# Extract and test bash commands from tutorials
# (Manual verification recommended)
```

### Check Cross-References
```bash
# Verify tutorials link to each other
grep "federation-advanced-tutorial" docs/content/tutorials/federation-simple-tutorial.md
grep "federation-simple-tutorial" docs/content/tutorials/federation-advanced-tutorial.md
```

---

## 📊 Deliverables

1. ✅ federated-builds.md enhanced (+100 lines)
2. ✅ federation-simple-tutorial.md created (150 lines)
3. ✅ federation-advanced-tutorial.md created (250 lines)
4. ✅ All examples tested and working
5. ✅ Cross-references complete

---

## 🔄 Commit Strategy

**Commit after each file**:

```bash
# Commit 1: Enhanced user guide
git add docs/content/user-guides/federated-builds.md
git commit -m "docs: enhance federated-builds user guide

Added comprehensive sections:
- Command-line reference (all options + env vars + exit codes)
- Error handling and debugging guide
- Performance optimization tips
- What's new section with recent updates

Lines added: ~100
Total: 512 lines

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Commit 2: Simple tutorial
git add docs/content/tutorials/federation-simple-tutorial.md
git commit -m "docs: add simple federation tutorial

Created beginner-friendly 2-module tutorial:
- Step-by-step guide (15 minutes)
- Local module setup
- Configuration creation
- Validation and testing
- Troubleshooting tips

Target: Beginners
Time: 15 minutes
Lines: 150

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Commit 3: Advanced tutorial
git add docs/content/tutorials/federation-advanced-tutorial.md
git commit -m "docs: add advanced federation tutorial

Created production-grade 5-module tutorial:
- InfoTech.io real-world scenario
- CSS path resolution
- Merge strategies
- Production deployment
- Performance optimization

Target: Advanced users
Time: 45 minutes
Lines: 250

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## ⏱️ Time Tracking

| Task | Estimated | Actual | Notes |
|------|-----------|--------|-------|
| 2.1: Enhance federated-builds.md | 1 hour | | |
| 2.2: Simple tutorial | 1 hour | | |
| 2.3: Advanced tutorial | 1 hour | | |
| **Total** | **3 hours** | | |

---

## 📝 Notes

### Key Points
- Don't duplicate existing content in federated-builds.md
- Use real examples (modules-simple.json, modules-infotech.json)
- Test all bash commands before documenting
- Keep tutorials practical and time-bound

### What NOT to Do
- Don't rewrite existing federated-builds.md sections
- Don't create fake examples (use existing JSON files)
- Don't add theoretical content (keep practical)
- Don't skip troubleshooting sections

### Dependencies
- Tutorials use example JSONs from Child #17
- Commands reference federated-build.sh from Child #16-19
- Performance numbers from Child #20 benchmarks

---

**Status**: Ready for implementation
**Previous Stage**: 001-readme-update.md
**Next Stage**: 003-developer-docs.md
**Updated**: 2025-10-19
