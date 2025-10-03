# Stage 1: Bug Reproduction

**Date**: October 2, 2025
**Status**: In Progress
**Objective**: Establish reproducible test case for Issue #14 using InfoTech.io corporate site

## Overview

This stage focuses on creating a reliable, observable reproduction of the caching bug described in Issue #14. We will use the InfoTech.io corporate site content and GitHub Pages workflow to demonstrate the issue in a real production scenario.

## Success Criteria

### Mandatory Requirements

- ✅ **Build without cache succeeds** with full content (370+ pages, ~10MB)
- ✅ **Build with cache fails** with template-only content (4 pages, ~76KB)
- ✅ **Observable difference** documented with logs, page counts, sizes
- ✅ **Reproducible** - can be repeated consistently
- ✅ **GitHub Pages workflow functional** - CI/CD environment working

### Evidence Requirements

- Build logs showing page counts
- Output size measurements
- Cache hit/miss indicators
- Screenshots or workflow run links
- Comparative analysis table

## Test Environment

### Repository Setup

**Primary Repository**: `info-tech-io/hugo-templates`
- Build scripts: `scripts/build.sh`
- Cache system: `scripts/cache.sh`
- GitHub Actions: `.github/workflows/`

**Content Repository**: `info-tech-io/info-tech`
- Corporate site content
- Used via `--content` parameter

### GitHub Pages Workflow

**Workflow File**: `.github/workflows/github-pages.yml` (to be verified/created)

**Expected Workflow**:
1. Checkout hugo-templates repo
2. Checkout info-tech repo for content
3. Run build with `--content` pointing to info-tech content
4. Deploy to GitHub Pages

## Reproduction Plan

### Step 1: Verify Workflow Existence

**Objective**: Check if GitHub Pages workflow exists and is functional

**Actions**:
```bash
# Check for workflow files
ls -la .github/workflows/

# Look for GitHub Pages related workflows
grep -r "github-pages\|pages" .github/workflows/
```

**Expected Outcomes**:
- **If workflow exists**: Proceed to Step 2 (verify functionality)
- **If workflow missing**: Create minimal workflow (Step 1b)

**Control Procedure**:
- ✅ Workflow file exists at `.github/workflows/*.yml`
- ✅ Workflow has `github-pages` or similar deployment step
- ✅ Workflow uses `--content` parameter

### Step 1b: Create/Fix GitHub Pages Workflow (if needed)

**Objective**: Ensure functional workflow for testing

**Minimal Workflow Template**:
```yaml
name: Deploy Corporate Site to GitHub Pages

on:
  workflow_dispatch:  # Manual trigger for testing
  push:
    branches: [main]
    paths:
      - 'scripts/**'
      - 'templates/**'

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout hugo-templates
        uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Checkout corporate site content
        uses: actions/checkout@v4
        with:
          repository: info-tech-io/info-tech
          path: corporate-content
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.148.0'
          extended: true

      - name: Build site (WITHOUT cache - baseline)
        run: |
          ./scripts/build.sh \
            --template=corporate \
            --content=./corporate-content \
            --output=./public \
            --no-cache \
            --verbose

      - name: Collect build metrics (no-cache)
        run: |
          echo "Pages generated: $(find ./public -name '*.html' | wc -l)"
          echo "Output size: $(du -sh ./public | cut -f1)"
          ls -lah ./public/

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

**Control Procedure**:
- ✅ Workflow file created/updated
- ✅ Workflow can be manually triggered
- ✅ Hugo 0.148.0 installed
- ✅ Content repository cloned
- ✅ Build completes successfully

### Step 2: Baseline Build (Without Cache)

**Objective**: Establish baseline with `--no-cache` flag

**Test Command**:
```bash
./scripts/build.sh \
  --template=corporate \
  --content=./corporate-content \
  --output=./public-nocache \
  --no-cache \
  --verbose
```

**Data Collection**:
```bash
# Page count
echo "HTML pages: $(find ./public-nocache -name '*.html' | wc -l)"

# Output size
echo "Total size: $(du -sh ./public-nocache | cut -f1)"
echo "Detailed: $(du -h --max-depth=1 ./public-nocache)"

# File types
echo "File breakdown:"
find ./public-nocache -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn

# RSS/XML feeds
echo "RSS/XML files:"
find ./public-nocache -name '*.xml' -o -name 'index.xml'
```

**Expected Results**:
- **Page count**: 300-400 pages
- **Output size**: 8-12 MB
- **Content**: Corporate site pages (about, products, blog, etc.)
- **RSS feeds**: Custom corporate RSS with actual posts

**Control Procedure**:
- ✅ Build completes with exit code 0
- ✅ Output directory contains 300+ HTML files
- ✅ Output size is 8+ MB
- ✅ Sample page contains corporate content (not template placeholders)
- ✅ RSS feed contains actual blog posts

### Step 3: Cached Build (First Run - Cache Miss)

**Objective**: Build WITH cache enabled, first run (should populate cache)

**Preparation**:
```bash
# Clear any existing cache
./scripts/build.sh --cache-clear

# Verify cache is empty
ls -la ~/.hugo-template-cache/
```

**Test Command**:
```bash
./scripts/build.sh \
  --template=corporate \
  --content=./corporate-content \
  --output=./public-cache-first \
  --verbose
```

**Data Collection**:
```bash
# Cache status
./scripts/cache.sh stats

# Build output
echo "HTML pages: $(find ./public-cache-first -name '*.html' | wc -l)"
echo "Total size: $(du -sh ./public-cache-first | cut -f1)"

# Cache directory
echo "Cache size: $(du -sh ~/.hugo-template-cache/ | cut -f1)"
ls -lah ~/.hugo-template-cache/l2/
```

**Expected Results**:
- **Cache miss** recorded
- **Page count**: 300-400 pages (same as no-cache)
- **Cache populated**: Cache directory not empty
- **Content correct**: Corporate content present

**Control Procedure**:
- ✅ Build completes successfully
- ✅ Cache miss logged in output
- ✅ Page count matches baseline (~370 pages)
- ✅ Cache directory created and populated
- ✅ Content matches baseline (corporate, not template)

### Step 4: Cached Build (Second Run - Cache Hit) **🔴 BUG EXPECTED**

**Objective**: Build WITH cache enabled, second run (cache hit - **BUG SHOULD MANIFEST**)

**Test Command**:
```bash
./scripts/build.sh \
  --template=corporate \
  --content=./corporate-content \
  --output=./public-cache-second \
  --verbose
```

**Data Collection**:
```bash
# Cache status
./scripts/cache.sh stats

# Build output
echo "HTML pages: $(find ./public-cache-second -name '*.html' | wc -l)"
echo "Total size: $(du -sh ./public-cache-second | cut -f1)"

# Content analysis
echo "Checking sample pages:"
cat ./public-cache-second/index.html | grep -o "<title>.*</title>"
find ./public-cache-second -name 'index.xml' | head -1 | xargs cat | head -20

# Compare with baseline
diff -r ./public-nocache ./public-cache-second | head -20
```

**Expected Results (BUG BEHAVIOR)**:
- ✅ **Cache hit** recorded
- ❌ **Page count**: ~4 pages (NOT 370+)
- ❌ **Output size**: ~76KB (NOT 8-12MB)
- ❌ **Content**: Template placeholders, not corporate content
- ❌ **RSS feeds**: Template RSS, not corporate posts

**Control Procedure - BUG CONFIRMED if**:
- ✅ Cache hit logged in output
- ✅ Page count < 10 (expected 370+)
- ✅ Output size < 100KB (expected ~10MB)
- ✅ Sample page shows template content (not corporate)
- ✅ Significant difference from baseline build

### Step 5: Comparative Analysis

**Objective**: Document clear evidence of the bug

**Comparison Table**:
```markdown
| Metric | Baseline (--no-cache) | First Build (cache miss) | Second Build (cache hit) | Expected | Status |
|--------|----------------------|--------------------------|-------------------------|----------|--------|
| Page Count | 370 | 370 | **4** | 370 | ❌ FAILED |
| Output Size | 9.7MB | 9.7MB | **76KB** | 9.7MB | ❌ FAILED |
| Content Type | Corporate | Corporate | **Template** | Corporate | ❌ FAILED |
| RSS Entries | 50+ posts | 50+ posts | **Template** | 50+ posts | ❌ FAILED |
| Build Time | 45s | 45s | 0.5s | 0.5s | ✅ (wrong content) |
| Cache Status | Disabled | Miss | **Hit** | Hit | ✅ |
```

**Control Procedure**:
- ✅ All three builds completed
- ✅ Clear metrics captured for each
- ✅ Bug manifests in cached build (second run)
- ✅ Difference is reproducible
- ✅ Evidence documented with logs

## GitHub Actions Testing

### Manual Workflow Trigger

**Objective**: Run workflow manually to verify bug in CI/CD environment

**Steps**:
1. Go to GitHub Actions tab
2. Select workflow (or create test workflow)
3. Click "Run workflow"
4. Monitor execution
5. Collect artifacts/logs

**Variations to Test**:
```yaml
# Test 1: Without cache
- name: Build (no cache)
  run: ./scripts/build.sh --content=./corporate-content --no-cache

# Test 2: With cache (first run)
- name: Build (with cache - first)
  run: ./scripts/build.sh --content=./corporate-content

# Test 3: With cache (second run - should reuse)
- name: Build (with cache - second)
  run: ./scripts/build.sh --content=./corporate-content
```

**Control Procedure**:
- ✅ Workflow runs complete successfully
- ✅ Logs show cache hit/miss
- ✅ Artifacts show different output sizes
- ✅ Bug reproducible in CI environment

## Troubleshooting Guide

### If Workflow Doesn't Exist
- Create minimal workflow from Step 1b template
- Commit and push to trigger workflow
- Verify in GitHub Actions tab

### If Workflow Fails
- Check Hugo version compatibility (need 0.148.0+)
- Verify content repository access (may need PAT token)
- Check submodules initialization (themes/compose)
- Review workflow logs for specific errors

### If Bug Doesn't Reproduce
- Verify cache is actually enabled (check `CACHE_ENABLED`)
- Clear cache and retry: `./scripts/build.sh --cache-clear`
- Check cache directory: `ls -la ~/.hugo-template-cache/`
- Verify `--content` parameter is being used
- Check build.sh version (should include caching from Epic #2)

### If Cache Directory Not Found
- Check `CACHE_ROOT` environment variable
- Default location: `~/.hugo-template-cache/`
- Verify cache system initialized: `./scripts/cache.sh init`
- Check permissions on cache directory

## Expected Timeline

| Step | Duration | Status |
|------|----------|--------|
| Workflow verification | 15-30 min | Pending |
| Baseline build | 5 min | Pending |
| Cached builds | 10 min | Pending |
| Analysis & documentation | 15 min | Pending |
| **Total** | **45-60 min** | Pending |

## Deliverables

### Documentation
- [x] This file (`001-reproduction.md`) - reproduction plan
- [ ] `001-progress.md` - execution results and evidence
- [ ] Screenshots/logs in `docs/proposals/14-*/evidence/` (if needed)

### Evidence
- Build logs (no-cache vs with-cache)
- Page count comparisons
- Output size measurements
- Cache statistics
- Workflow run links

### Git Commit
After completing reproduction:
```bash
git add docs/proposals/14-caching-system-blocks-custom-content/
git commit -m "docs(issue-14): Stage 1 - bug reproduction completed

- Verified bug reproducibility with InfoTech.io corporate site
- Documented baseline (--no-cache): 370 pages, 9.7MB
- Documented bug behavior (cache hit): 4 pages, 76KB
- Cache hits with different content sources use same cache key
- Ready for Hypothesis #1 verification

Evidence: 001-progress.md"
```

---

**Status**: 📋 **PLAN READY** - Ready for execution
**Next**: Execute reproduction plan and document results in `001-progress.md`
