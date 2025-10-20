# Federation Migration Checklist

**Purpose**: Migrate from single-site Hugo build to federated multi-module build
**Time Required**: 2-4 hours  
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
- [ ] Decision on federation strategy
- [ ] Backup of current site

---

## Phase 1: Assessment (30 minutes)

### 1.1 Identify Module Boundaries
- [ ] Review current site structure
- [ ] Identify logical content boundaries (docs, blog, API, tutorials)
- [ ] Determine which sections should be independent modules
- [ ] Map current directory structure to future modules

**Example Mapping**:
```
Current site:
  content/
    ├── docs/       → Module 1 (main docs)
    ├── api/        → Module 2 (API reference)
    ├── blog/       → Module 3 (blog)
    └── tutorials/  → Module 4 (tutorials)
```

### 1.2 Check Compatibility
- [ ] Review [compatibility guide](../user-guides/federation-compatibility.md)
- [ ] Verify no hardcoded absolute paths in content
- [ ] Check for CSS paths that need rewriting
- [ ] Identify potential path conflicts between modules

### 1.3 Choose Federation Strategy
- [ ] **download-merge-deploy**: Pre-built modules from GitHub Releases (fastest, CI/CD)
- [ ] **merge-and-build**: Build all modules from source (development, full control)
- [ ] **preserve-base-site**: Add modules to existing site (incremental)

---

## Phase 2: Preparation (30-60 minutes)

### 2.1 Backup Current Site
```bash
cp -r site-output site-output-backup
git tag migration-backup-$(date +%Y%m%d)
git push origin migration-backup-$(date +%Y%m%d)
```
- [ ] Backup created and verified
- [ ] Backup tag pushed to remote

### 2.2 Organize Module Repositories
For each module:
- [ ] Create separate repository (or use existing)
- [ ] Ensure standard Hugo structure (content/, static/, config)
- [ ] Test building module independently with `build.sh`
- [ ] Tag release if using download-merge-deploy

### 2.3 Create modules.json Configuration
```bash
cp docs/content/examples/modules-simple.json modules.json
```

**Edit modules.json**:
```json
{
  "baseSite": {
    "name": "main-site",
    "source": {"type": "local", "path": "./base-site"}
  },
  "modules": [
    {
      "name": "module-api",
      "source": {"type": "github", "repo": "org/api-docs", "tag": "v1.0.0"},
      "priority": 1
    }
  ],
  "strategy": "merge-and-build"
}
```

- [ ] Configuration file created
- [ ] Base site configured
- [ ] All modules added
- [ ] Validate: `node scripts/validate.js modules.json schemas/modules.schema.json`

---

## Phase 3: Migration (30-60 minutes)

### 3.1 Test Dry Run
```bash
./scripts/federated-build.sh --config=modules.json --dry-run
```
- [ ] Dry run successful
- [ ] No configuration errors
- [ ] All modules accessible

### 3.2 Perform First Federated Build
```bash
./scripts/federated-build.sh --config=modules.json --output=federated-output
```
- [ ] Build completed successfully
- [ ] No merge conflicts
- [ ] Output directory created

### 3.3 Compare Outputs
```bash
diff -r site-output federated-output | head -50
echo "Old: $(find site-output -type f | wc -l) files"
echo "New: $(find federated-output -type f | wc -l) files"
```
- [ ] File counts reasonable (new ≥ old)
- [ ] No unexpected missing content

---

## Phase 4: Verification (30 minutes)

### 4.1 Test Local Server
```bash
cd federated-output
python3 -m http.server 8000
```
Visit http://localhost:8000

**Verify**:
- [ ] Homepage loads correctly
- [ ] Navigation works
- [ ] All modules accessible
- [ ] CSS styling correct
- [ ] Images load
- [ ] Internal links work

### 4.2 Validate Content Integrity
- [ ] All original content present
- [ ] Module content merged correctly
- [ ] No duplicate pages
- [ ] YAML front matter preserved

### 4.3 Check CSS Path Rewriting
```bash
grep -r "\.\./" federated-output/content/ | grep -i "\.css"
# Should return empty
```
- [ ] No relative CSS paths remain

---

## Phase 5: CI/CD Update (30 minutes)

### 5.1 Update GitHub Actions
```yaml
- name: Run Federated Build
  run: |
    ./scripts/federated-build.sh \
      --config=modules.json \
      --output=public \
      --minify
```
- [ ] Workflow file updated
- [ ] Correct output directory (public)

### 5.2 Test CI/CD
- [ ] Push changes to trigger workflow
- [ ] Build succeeds in CI
- [ ] Deployed site verified

---

## Rollback Plan

### Immediate Rollback
```bash
cp -r site-output-backup site-output
git checkout HEAD~1 .github/workflows/deploy.yml
./scripts/build.sh --input=site-source --output=site-output
```

### Restore from Tag
```bash
git checkout migration-backup-YYYYMMDD
```

---

## Troubleshooting

**Module Not Found**: Verify repository URL and access
**Merge Conflicts**: Adjust module priorities
**CSS Not Loading**: Check CSS path rewriting
**Build Timeout**: Switch to download-merge-deploy strategy
**Validation Errors**: Run `node scripts/validate.js modules.json schemas/modules.schema.json`

---

## Post-Migration

- [ ] Federation working locally
- [ ] CI/CD pipeline tested
- [ ] Deployed site verified
- [ ] Documentation updated
- [ ] Team trained on new workflow
- [ ] Monitoring setup

---

## Getting Help

- [User Guide](../user-guides/federated-builds.md)
- [Simple Tutorial](federation-simple-tutorial.md)
- [Advanced Tutorial](federation-advanced-tutorial.md)
- [Compatibility Guide](../user-guides/federation-compatibility.md)

---

**Last Updated**: 2025-10-20
