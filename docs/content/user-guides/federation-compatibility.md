# Federation Compatibility Guide

**Purpose**: Determine if federated builds are right for your project
**Last Updated**: 2025-10-20

---

## When to Use Federation

### ✅ Good Fit for Federation

**Multi-Team Content Collaboration**
- Multiple teams maintain separate content repositories
- Each team needs independent development workflow
- Centralized deployment required

**Example**: InfoTech.io with 5 teams (docs, API, tutorials, blog, FAQ)

**Multi-Repository Documentation**
- Product with multiple components
- Each component has its own documentation
- Need unified documentation site

**Example**: Main product + plugins + community content

**Content from Multiple Sources**
- Content in different Git repositories
- Some content pre-built (GitHub Releases)
- Some content built from source

---

### ⚠️ Consider Alternatives

**Simple Single-Site Projects**
- Single team, single repository
- All content in one location
- **Alternative**: Use Layer 1 (`build.sh`) directly

**Very Small Sites** (<10 pages)
- Limited content, no module boundaries
- **Alternative**: Standard Hugo workflow

**Complex Inter-Module Dependencies**
- Modules heavily reference each other's content
- **Alternative**: Monorepo with single build

---

### ❌ Not Suitable

**Real-Time Content**
- Content needs real-time updates
- **Alternative**: Dynamic CMS

**Hugo Modules (Go Modules)**
- Using Hugo's built-in module system
- **Alternative**: Hugo modules + single build

---

## Compatibility Requirements

### Repository Structure

**Required**:
- Standard Hugo directory structure
- `content/` directory exists
- Valid Hugo configuration

**Optional**:
- `static/`, `layouts/` directories

**Not Supported**:
- Non-Hugo static sites

---

### Content Requirements

**Compatible**:
- Standard Markdown files
- YAML/TOML/JSON front matter
- Relative links within module
- Hugo shortcodes

**Requires Attention**:
- Absolute paths (may break)
- CSS with relative paths - **auto-rewritten**
- Inter-module links - configure carefully

**Not Compatible**:
- Hardcoded absolute URLs
- JavaScript depending on specific URL structure

---

### Build Requirements

**Required**:
- Hugo installed (same version across modules)
- Bash shell (Linux/macOS/WSL)
- Git (for git-based sources)
- Node.js (for schema validation)

---

## Known Limitations

### 1. CSS Path Rewriting
**Issue**: CSS files with relative paths
**Status**: ✅ Auto-detected and rewritten
**Action**: None (handled automatically)

### 2. JavaScript Paths
**Issue**: JavaScript may have hardcoded paths
**Status**: ⚠️ Manual review required
**Action**: Review and update JS paths if needed

### 3. Build Time
**Issue**: Building N modules takes N × single-module time
**Status**: ⚠️ Expected behavior
**Mitigation**: Use `download-merge-deploy` strategy

### 4. Theme Compatibility
**Issue**: Each module can have its own theme
**Status**: ⚠️ May cause inconsistency
**Mitigation**: Use same theme across modules

### 5. Hugo Version Differences
**Issue**: Modules built with different Hugo versions
**Status**: ⚠️ May cause rendering differences
**Mitigation**: Standardize Hugo version

---

## Decision Matrix

| Scenario | Layer 1 | Layer 2 |
|----------|---------|---------|
| Single repository | ✅ | ❌ |
| 2-5 repositories | ⚠️ | ✅ |
| 6+ repositories | ❌ | ✅ |
| Single team | ✅ | ⚠️ |
| Multi-team | ❌ | ✅ |
| Shared content | ✅ | ❌ |
| Independent content | ⚠️ | ✅ |

---

## Testing Your Setup

### Step 1: Create Test Configuration
```bash
cp docs/content/examples/modules-simple.json test-modules.json
```

### Step 2: Dry Run
```bash
./scripts/federated-build.sh --config=test-modules.json --dry-run
```

### Step 3: Test Build
```bash
./scripts/federated-build.sh --config=test-modules.json --output=test-output
```

### Step 4: Verify
```bash
cd test-output
python3 -m http.server 8000
```

### Step 5: Evaluate
- Does content look correct?
- Are there merge conflicts?
- Is build time acceptable?

---

## Getting Help

- [User Guide](federated-builds.md)
- [Simple Tutorial](../tutorials/federation-simple-tutorial.md)
- [Migration Checklist](../tutorials/federation-migration-checklist.md)

---

**Last Updated**: 2025-10-20
