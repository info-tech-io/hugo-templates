# Stage 4: Migration Resources

**Child Issue**: #21 - Documentation & Migration
**Stage**: 4 of 4
**Priority**: LOW (README > User guides > Developer docs > Migration)
**Estimated Duration**: 2 hours
**Dependencies**: Stage 3 (Developer Docs)

---

## 🎯 Objective

Create simplified migration resources to help users transition from single-site builds (Layer 1) to federated builds (Layer 2), with clear compatibility guidance and step-by-step checklist.

---

## 📋 Tasks Breakdown

### Task 4.1: Create Migration Checklist (1 hour)

**Goal**: Step-by-step guide for migrating to federated builds

**Actions**:
1. Create new file: `docs/content/tutorials/federation-migration-checklist.md`
2. Provide "Before You Start" prerequisites
3. Create phased migration checklist (Assess → Prepare → Migrate → Verify)
4. Include rollback instructions
5. Add troubleshooting for common migration issues

**Content to Include**:

**File: federation-migration-checklist.md**

```markdown
# Federation Migration Checklist

## Overview

**Purpose**: Migrate from single-site Hugo build to federated multi-module build
**Time Required**: 2-4 hours (depending on complexity)
**Prerequisite**: Existing Hugo site built with build.sh (Layer 1)

---

## Before You Start

### Prerequisites
- [ ] Hugo site currently using `build.sh` (Layer 1)
- [ ] Site builds successfully with existing workflow
- [ ] Git repositories identified for each module
- [ ] Access to all module repositories
- [ ] Basic understanding of JSON configuration

### What You'll Need
- [ ] List of modules/content sections to federate
- [ ] Repository URLs or local paths for each module
- [ ] Decision on federation strategy (download-merge-deploy, merge-and-build, or preserve-base-site)
- [ ] Backup of current site

---

## Phase 1: Assessment (30 minutes)

### 1.1 Identify Module Boundaries
- [ ] Review current site structure
- [ ] Identify logical content boundaries (e.g., docs, blog, API reference)
- [ ] Determine which sections should be independent modules
- [ ] Map current directory structure to future modules

**Example**:
```
Current site:
  content/
    ├── docs/       → Module 1 (main docs)
    ├── api/        → Module 2 (API reference)
    ├── blog/       → Module 3 (blog posts)
    └── tutorials/  → Module 4 (tutorials)
```

### 1.2 Check Compatibility
- [ ] Review [compatibility guide](../user-guides/federation-compatibility.md)
- [ ] Verify no hardcoded absolute paths in content
- [ ] Check for CSS paths that need rewriting
- [ ] Identify potential path conflicts between modules

### 1.3 Choose Federation Strategy
- [ ] **download-merge-deploy**: Pre-built modules from GitHub Releases ✅ (recommended for CI/CD)
- [ ] **merge-and-build**: Build all modules from source ✅ (recommended for development)
- [ ] **preserve-base-site**: Add modules to existing site ✅ (recommended for incremental migration)

---

## Phase 2: Preparation (30-60 minutes)

### 2.1 Backup Current Site
```bash
# Create backup
cp -r site-output site-output-backup
git tag migration-backup-$(date +%Y%m%d)
git push origin migration-backup-$(date +%Y%m%d)
```
- [ ] Backup created
- [ ] Backup verified
- [ ] Backup tag pushed to remote

### 2.2 Organize Module Repositories
For each module:
- [ ] Create separate repository (or use existing)
- [ ] Ensure repository has standard Hugo structure:
  ```
  module-repo/
    ├── content/
    ├── static/
    ├── layouts/ (optional)
    └── config.toml (or config.yaml)
  ```
- [ ] Test building module independently with `build.sh`
- [ ] Tag release if using download-merge-deploy strategy

### 2.3 Create modules.json Configuration
```bash
# Copy example as starting point
cp docs/content/examples/modules-simple.json modules.json
```

- [ ] Configuration file created
- [ ] Base site configured
- [ ] All modules added
- [ ] Strategy selected
- [ ] Validate configuration:
  ```bash
  node scripts/validate.js modules.json schemas/modules.schema.json
  ```

**Example Configuration**:
```json
{
  "baseSite": {
    "name": "main-site",
    "source": {
      "type": "local",
      "path": "./base-site"
    }
  },
  "modules": [
    {
      "name": "module-api",
      "source": {
        "type": "github",
        "repo": "your-org/module-api",
        "tag": "v1.0.0"
      },
      "priority": 1
    },
    {
      "name": "module-blog",
      "source": {
        "type": "git",
        "url": "https://github.com/your-org/module-blog.git",
        "branch": "main"
      },
      "priority": 2
    }
  ],
  "strategy": "merge-and-build"
}
```

---

## Phase 3: Migration (30-60 minutes)

### 3.1 Test Dry Run
```bash
# Test federation without actually building
./scripts/federated-build.sh --config=modules.json --dry-run
```
- [ ] Dry run successful
- [ ] No configuration errors
- [ ] All modules accessible
- [ ] No validation failures

### 3.2 Perform First Federated Build
```bash
# Run first federated build
./scripts/federated-build.sh --config=modules.json --output=federated-output
```
- [ ] Build completed successfully
- [ ] No merge conflicts
- [ ] All modules merged
- [ ] Output directory created

### 3.3 Compare Outputs
```bash
# Compare old vs new output
diff -r site-output federated-output | head -50

# Check file counts
echo "Old site: $(find site-output -type f | wc -l) files"
echo "New site: $(find federated-output -type f | wc -l) files"

# Check for missing content
# (Federated site should have same or more content)
```
- [ ] File counts are reasonable (new >= old)
- [ ] No unexpected missing content
- [ ] CSS/JS files present
- [ ] Static assets copied correctly

---

## Phase 4: Verification (30 minutes)

### 4.1 Test Local Server
```bash
# Serve federated site locally
cd federated-output
python3 -m http.server 8000
# Visit http://localhost:8000
```

**Verify**:
- [ ] Homepage loads correctly
- [ ] Navigation works
- [ ] All modules accessible
- [ ] CSS styling correct (no broken styles)
- [ ] Images load
- [ ] Internal links work
- [ ] No 404 errors in browser console

### 4.2 Validate Content Integrity
- [ ] All original content present
- [ ] Module content merged correctly
- [ ] No duplicate pages
- [ ] YAML front matter preserved
- [ ] Markdown formatting intact

### 4.3 Check CSS Path Rewriting
```bash
# Check for CSS path issues
grep -r "\.\./" federated-output/content/ | grep -i "\.css"
# Should return empty if rewriting worked

# Check rewritten paths
grep -r "/static/" federated-output/content/ | head -10
```
- [ ] No relative CSS paths (`../`)
- [ ] All CSS paths rewritten to absolute/correct paths
- [ ] Styles render correctly

---

## Phase 5: Update CI/CD (30 minutes)

### 5.1 Update GitHub Actions Workflow
```yaml
# .github/workflows/deploy.yml
name: Deploy Federated Site

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'

      - name: Run Federated Build
        run: |
          chmod +x scripts/federated-build.sh
          ./scripts/federated-build.sh \
            --config=modules.json \
            --output=public \
            --minify

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

- [ ] Workflow file updated
- [ ] Correct federation command used
- [ ] Output directory correct (`public`)
- [ ] Minification enabled

### 5.2 Test CI/CD Pipeline
- [ ] Push changes to trigger workflow
- [ ] Monitor workflow execution
- [ ] Verify build succeeds in CI
- [ ] Check deployed site

---

## Rollback Plan

If migration fails or issues arise:

### Immediate Rollback
```bash
# 1. Stop using federated build
# 2. Restore backup
cp -r site-output-backup site-output

# 3. Restore old CI/CD workflow
git checkout HEAD~1 .github/workflows/deploy.yml

# 4. Redeploy old site
./scripts/build.sh --input=site-source --output=site-output
```

### Restore from Git Tag
```bash
git checkout migration-backup-YYYYMMDD
git checkout -b rollback-branch
# Test, then merge if needed
```

---

## Troubleshooting Common Issues

### Issue 1: Module Not Found
**Symptom**: `ERROR: Module 'module-name' not found`

**Solutions**:
- Verify repository URL is correct
- Check repository access (public/private, credentials)
- For local modules, verify path is correct
- For GitHub releases, verify tag exists

### Issue 2: Merge Conflicts
**Symptom**: `WARNING: Conflict detected in path X`

**Solutions**:
- Review conflict in `federated-output`
- Adjust module priority to control merge order
- Use `preserve-base-site` strategy to favor base site
- Manually resolve conflicts after build

### Issue 3: CSS Not Loading
**Symptom**: Site renders without styles

**Solutions**:
- Check console for 404 errors
- Verify CSS files in `federated-output/static/`
- Check CSS path rewriting: `grep -r "\.\./" federated-output/content/`
- Ensure all modules use consistent CSS paths

### Issue 4: Build Timeout
**Symptom**: Build hangs or times out

**Solutions**:
- Switch to `download-merge-deploy` strategy (faster)
- Check internet connection (for remote fetching)
- Verify no circular dependencies
- Check logs for specific module causing delay

### Issue 5: Configuration Validation Errors
**Symptom**: `ERROR: Schema validation failed`

**Solutions**:
- Validate JSON syntax: `node scripts/validate.js modules.json schemas/modules.schema.json`
- Check oneOf constraints (local vs remote source)
- Ensure all required fields present
- Verify strategy is valid (download-merge-deploy, merge-and-build, preserve-base-site)

---

## Post-Migration Checklist

- [ ] Federated build working locally
- [ ] CI/CD pipeline updated and tested
- [ ] Deployed site verified
- [ ] Documentation updated (if custom modifications)
- [ ] Team trained on new workflow
- [ ] Backup/rollback plan documented
- [ ] Monitoring setup for new pipeline

---

## Next Steps

After successful migration:
1. **Optimize**: Profile build times, consider strategy changes
2. **Monitor**: Watch CI/CD builds for failures
3. **Iterate**: Add more modules as needed
4. **Document**: Record any custom modifications
5. **Share**: Help others by contributing improvements

---

## Getting Help

- **User Guide**: [Federated Builds Guide](../user-guides/federated-builds.md)
- **Tutorials**: [Simple Tutorial](federation-simple-tutorial.md) | [Advanced Tutorial](federation-advanced-tutorial.md)
- **Troubleshooting**: [Compatibility Guide](../user-guides/federation-compatibility.md)
- **Issues**: [GitHub Issues](https://github.com/info-tech-io/hugo-templates/issues)

---

**Migration Type**: Single-site → Federated
**Estimated Time**: 2-4 hours
**Difficulty**: Intermediate
**Prerequisites**: Existing Hugo site with build.sh

**Status**: Ready to use
**Last Updated**: 2025-10-19
```

**Validation**:
- Checklist is comprehensive but not overwhelming
- Phased approach (Assess → Prepare → Migrate → Verify)
- Rollback plan included
- Common issues covered
- Practical examples included

**Estimated Lines**: ~400 lines

---

### Task 4.2: Create Compatibility Guide (1 hour)

**Goal**: Help users determine if federation is right for their use case

**Actions**:
1. Create new file: `docs/content/user-guides/federation-compatibility.md`
2. Provide "When to Use Federation" decision guide
3. Explain compatibility requirements
4. List known limitations
5. Provide alternative solutions

**Content to Include**:

**File: federation-compatibility.md**

```markdown
# Federation Compatibility Guide

## Overview

This guide helps you determine if federated builds are appropriate for your Hugo site and identifies potential compatibility issues.

---

## When to Use Federation

### ✅ Good Fit for Federation

**Multi-Team Content Collaboration**
- Multiple teams maintain separate content repositories
- Each team needs independent development workflow
- Centralized deployment required
- Content organized into clear boundaries

**Example**: InfoTech.io with 5 teams (docs, API, tutorials, blog, FAQ)

**Multi-Repository Documentation**
- Product with multiple components
- Each component has its own documentation
- Need unified documentation site
- Components evolve independently

**Example**: Main product + plugins + community content

**Content from Multiple Sources**
- Content in different Git repositories
- Some content pre-built (GitHub Releases)
- Some content built from source
- Need single static site output

**Example**: Editorial (Git) + Product data (API) + User content (DB → Hugo)

### ⚠️ Consider Alternatives

**Simple Single-Site Projects**
- Single team, single repository
- All content in one location
- No need for module independence
- **Alternative**: Use Layer 1 (`build.sh`) directly

**Very Small Sites (<10 pages)**
- Limited content
- No clear module boundaries
- Build time not a concern
- **Alternative**: Standard Hugo workflow

**Complex Inter-Module Dependencies**
- Modules heavily reference each other's content
- Shared layouts critical
- Tight coupling between sections
- **Alternative**: Monorepo with single build

### ❌ Not Suitable for Federation

**Real-Time Content**
- Content needs real-time updates
- Static site generation too slow
- **Alternative**: Dynamic CMS or API-driven approach

**Shared Hugo Modules (Go Modules)**
- Using Hugo's built-in module system
- Modules define themes/partials
- **Alternative**: Hugo modules + single build

---

## Compatibility Requirements

### Repository Structure

**Required**:
- Standard Hugo directory structure
- `content/` directory exists
- Valid Hugo configuration (config.toml/yaml/json)

**Optional**:
- `static/` directory (merged if present)
- `layouts/` directory (merged if present)
- Custom archetypes

**Not Supported**:
- Non-Hugo static sites (must be Hugo sites)
- Raw HTML sites without Hugo structure

### Content Requirements

**Compatible**:
- Standard Markdown files (.md)
- YAML/TOML/JSON front matter
- Relative links within module
- Hugo shortcodes
- Static assets in module's `static/`

**Requires Attention**:
- Absolute paths (may break)
- CSS with relative paths (`../`) - **auto-rewritten**
- Inter-module links - **configure carefully**
- Shared static assets - **centralize in base site**

**Not Compatible**:
- Hardcoded absolute URLs to specific domains
- JavaScript depending on specific URL structure
- Build-time plugins (must be in all modules)

### Build Requirements

**Required**:
- Hugo installed (same version across modules)
- Bash shell (Linux/macOS/WSL)
- Git (for git-based sources)
- Node.js (for schema validation)

**Optional**:
- GitHub CLI (`gh`) for release downloads
- jq for JSON manipulation

---

## Known Limitations

### 1. CSS Path Rewriting
**Issue**: CSS files with relative paths (`../style.css`)
**Status**: ✅ Auto-detected and rewritten
**Action**: None (handled automatically)

### 2. JavaScript Paths
**Issue**: JavaScript may have hardcoded paths
**Status**: ⚠️ Manual review required
**Action**: Review and update JS paths if needed

### 3. Build Time
**Issue**: Building N modules takes N × single-module time
**Status**: ⚠️ Expected behavior
**Mitigation**: Use `download-merge-deploy` strategy for pre-built modules

### 4. Theme Compatibility
**Issue**: Each module can have its own theme
**Status**: ⚠️ May cause inconsistency
**Mitigation**: Use same theme across all modules, or centralize theme in base site

### 5. Hugo Version Differences
**Issue**: Modules built with different Hugo versions
**Status**: ⚠️ May cause rendering differences
**Mitigation**: Standardize Hugo version across all modules

### 6. Memory Usage
**Issue**: Large number of modules (>20) may use significant memory
**Status**: ⚠️ Monitor resource usage
**Mitigation**: Use `download-merge-deploy`, increase system resources

---

## Decision Matrix

| Scenario | Layer 1 (build.sh) | Layer 2 (federated-build.sh) |
|----------|-------------------|------------------------------|
| Single repository | ✅ Recommended | ❌ Overkill |
| 2-5 repositories | ⚠️ Possible | ✅ Recommended |
| 6+ repositories | ❌ Difficult | ✅ Recommended |
| Single team | ✅ Recommended | ⚠️ Optional |
| Multi-team | ❌ Difficult | ✅ Recommended |
| Shared content | ✅ Recommended | ❌ Complex |
| Independent content | ⚠️ Possible | ✅ Recommended |
| Fast builds (<1 min) | ✅ Recommended | ⚠️ May add overhead |
| Slow builds (>5 min) | ⚠️ Bottleneck | ✅ Parallelizable |

---

## Migration Considerations

### From Single-Site to Federation

**Pros**:
- Module independence
- Parallel development
- Clear content boundaries
- Easier team collaboration

**Cons**:
- More complex build process
- Additional configuration required
- Learning curve for team
- More repositories to manage

**Timeline**: 2-4 hours for initial migration

### From Federation to Single-Site

**Pros**:
- Simpler build process
- Single repository to manage
- Faster iteration for small teams

**Cons**:
- Lose module independence
- Harder to scale to multiple teams
- Tighter coupling

**Timeline**: 1-2 hours (merge repositories)

---

## Testing Your Setup

Before committing to federation, test with your actual content:

### Step 1: Create Test Configuration
```bash
# Use simple 2-module example
cp docs/content/examples/modules-simple.json test-modules.json
# Edit test-modules.json with your repositories
```

### Step 2: Dry Run
```bash
./scripts/federated-build.sh --config=test-modules.json --dry-run
```

### Step 3: Test Build
```bash
./scripts/federated-build.sh --config=test-modules.json --output=test-output
```

### Step 4: Verify Output
```bash
cd test-output
python3 -m http.server 8000
# Visit http://localhost:8000 and verify
```

### Step 5: Evaluate
- Does content look correct?
- Are there merge conflicts?
- Is build time acceptable?
- Does complexity justify benefits?

---

## Getting Help

**Questions?**
- Review [User Guide](federated-builds.md)
- Try [Simple Tutorial](../tutorials/federation-simple-tutorial.md)
- Check [Troubleshooting](federated-builds.md#troubleshooting)

**Issues?**
- Search [GitHub Issues](https://github.com/info-tech-io/hugo-templates/issues)
- Review [Migration Checklist](../tutorials/federation-migration-checklist.md)

**Still Unsure?**
- Open a discussion on GitHub
- Describe your use case
- Ask for recommendations

---

**Last Updated**: 2025-10-19
**Applies To**: Layer 2 (federated-build.sh)
**Version**: 1.0
```

**Validation**:
- Clear decision guidance
- Practical compatibility matrix
- Known limitations documented
- Testing steps included

**Estimated Lines**: ~300 lines

---

## 📁 Files Modified/Created

### New Files (Created)

#### docs/content/tutorials/federation-migration-checklist.md
**Type**: CREATE (new file)
**Purpose**: Step-by-step migration guide
**Content**: 5-phase checklist (Assess, Prepare, Migrate, Verify, Update CI/CD)
**Lines**: ~400 lines

#### docs/content/user-guides/federation-compatibility.md
**Type**: CREATE (new file)
**Purpose**: Compatibility and decision guide
**Content**: When to use federation, requirements, limitations, decision matrix
**Lines**: ~300 lines

**Total New Content**: ~700 lines

---

## ✅ Success Criteria

- [ ] federation-migration-checklist.md created with 400+ lines
- [ ] Phased approach (5 phases) clearly structured
- [ ] Rollback plan included
- [ ] Troubleshooting section comprehensive
- [ ] federation-compatibility.md created with 300+ lines
- [ ] Decision matrix included
- [ ] Known limitations documented
- [ ] "When to Use Federation" guidance clear
- [ ] Testing steps provided
- [ ] All links functional

---

## 🧪 Validation Commands

### Check Migration Checklist
```bash
wc -l docs/content/tutorials/federation-migration-checklist.md
# Should be ~400 lines

grep "Phase [1-5]:" docs/content/tutorials/federation-migration-checklist.md | wc -l
# Should be 5 (5 phases)

grep "\- \[ \]" docs/content/tutorials/federation-migration-checklist.md | wc -l
# Should be > 30 (many checklist items)
```

### Check Compatibility Guide
```bash
wc -l docs/content/user-guides/federation-compatibility.md
# Should be ~300 lines

grep "✅\|⚠️\|❌" docs/content/user-guides/federation-compatibility.md | wc -l
# Should be > 15 (decision indicators)

grep "When to Use Federation\|Known Limitations\|Decision Matrix" docs/content/user-guides/federation-compatibility.md | wc -l
# Should be 3 (all sections present)
```

### Verify File Naming
```bash
# All new files should have "federation" in name
ls docs/content/tutorials/federation-*.md docs/content/user-guides/federation-*.md 2>/dev/null | \
  xargs -I {} echo "✅ {}"
```

---

## 📊 Deliverables

1. ✅ federation-migration-checklist.md (~400 lines)
   - 5-phase migration process
   - Rollback plan
   - Troubleshooting guide
   - CI/CD update instructions

2. ✅ federation-compatibility.md (~300 lines)
   - When to use federation
   - Compatibility requirements
   - Known limitations
   - Decision matrix
   - Testing steps

**Total**: 2 new files, ~700 lines

---

## 🔄 Commit Strategy

**Commit 1: Migration Checklist**
```bash
git add docs/content/tutorials/federation-migration-checklist.md
git commit -m "docs: add federation migration checklist

Step-by-step guide for migrating to federated builds:
- 5-phase approach (Assess → Prepare → Migrate → Verify → CI/CD)
- Rollback plan for failed migrations
- Troubleshooting common issues
- Phased checklist with verification steps

Target: Users migrating from single-site to federation
Lines: ~400

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Commit 2: Compatibility Guide**
```bash
git add docs/content/user-guides/federation-compatibility.md
git commit -m "docs: add federation compatibility guide

Decision guide for federation adoption:
- When to use federation (use cases)
- Compatibility requirements
- Known limitations with mitigation
- Decision matrix (Layer 1 vs Layer 2)
- Testing steps before migration

Helps users determine if federation fits their needs
Lines: ~300

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## ⏱️ Time Tracking

| Task | Estimated | Actual | Notes |
|------|-----------|--------|-------|
| 4.1: Migration Checklist | 1 hour | | |
| 4.2: Compatibility Guide | 1 hour | | |
| **Total** | **2 hours** | | |

---

## 📝 Notes

### Key Points
- Migration is simplified to phased checklist (as requested)
- Compatibility guide helps users decide before investing time
- Rollback plan provides safety net
- Troubleshooting covers common issues found during testing
- All files use "federation" prefix (naming requirement met)

### What NOT to Do
- Don't make migration seem trivial (be honest about complexity)
- Don't overcomplicate checklist (keep actionable)
- Don't promise compatibility with non-Hugo sites
- Don't skip rollback plan (critical for confidence)

### Validation with Existing Docs
- Links to existing user guide (federated-builds.md)
- References tutorials created in Stage 2
- Complements developer docs from Stage 3
- Integrates with README section from Stage 1

---

**Status**: Ready for implementation
**Previous Stage**: 003-developer-docs.md
**Next Stage**: None (final stage)
**Updated**: 2025-10-19
