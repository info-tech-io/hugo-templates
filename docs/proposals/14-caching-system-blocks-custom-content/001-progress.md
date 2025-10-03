# Stage 1: Bug Reproduction - Progress Report

**Date Started**: October 3, 2025
**Date Completed**: October 3, 2025
**Status**: ✅ COMPLETE
**Stage Plan**: [001-reproduction.md](./001-reproduction.md)

## 📋 Execution Summary

Bug successfully reproduced and confirmed through GitHub Actions workflow testing in production environment (GitHub Pages). Root cause identified through cache key analysis - the `$CONTENT` parameter is **not included** in cache key generation, causing cache hits for different content sources.

### Objectives Completed
- [x] GitHub Pages workflow located in `info-tech-io.github.io` repository
- [x] Test workflow created for systematic bug reproduction
- [x] Cache key analysis performed with two different content sources
- [x] Bug confirmed: identical cache keys despite different `--content` parameters
- [x] Root cause identified in `scripts/build.sh` lines 729 and 768

## 🔍 Test Results

### Test Environment
- **Primary Repository**: `info-tech-io/info-tech-io.github.io` (GitHub Pages)
- **Build Framework**: `info-tech-io/hugo-templates`
- **Hugo Version**: 0.148.0+extended
- **Test Workflow**: `.github/workflows/test-cache-bug.yml`
- **Test Date**: October 3, 2025
- **Workflow Runs**:
  - Test 1: [#18221608898](https://github.com/info-tech-io/info-tech-io.github.io/actions/runs/18221608898)
  - Test 2: [#18221800796](https://github.com/info-tech-io/info-tech-io.github.io/actions/runs/18221800796)

### Step 1: Workflow Verification ✅

**Action**: Verified GitHub Pages workflow existence and configuration

**Location**: `info-tech-io.github.io/.github/workflows/deploy-corporate.yml`

**Key Findings**:
```yaml
# Line 75-78: Workaround already in place
if [ "${{ github.event.inputs.debug }}" = "true" ]; then
  scripts/build.sh ... --no-cache  # Workaround
else
  scripts/build.sh ... --no-cache  # Workaround
fi
```

**Observation**: Production workflow uses `--no-cache` flag as workaround for this bug.

**Status**: ✅ Workflow found, workaround confirmed

### Step 2: Test Workflow Creation ✅

**Action**: Created test workflow for systematic bug reproduction

**File**: `info-tech-io.github.io/.github/workflows/test-cache-bug.yml`

**Commits**:
- `3df8c36` - Initial test workflow
- `1c7a736` - Added content source selection

**Features**:
- Manual trigger via `workflow_dispatch`
- Support for cache enabled/disabled testing
- Support for multiple content sources (info-tech, hugo-templates)
- Automatic build analysis and validation

**Status**: ✅ Test infrastructure created

### Step 3: Cache Key Analysis ✅ **BUG CONFIRMED**

**Test 1**: Build with info-tech content (14 MD files)

```bash
Content: info-tech-io/info-tech/docs/content
Command: scripts/build.sh --content ./module-content/content
Cache: Enabled (miss expected - first build)
```

**Result**:
```
Cache Key: build_a121501bcd7fda5a9ecaff521a658fd463c564d5961e52f46dd7545e233b4fb5_cc5cb0a71f553b2fb3428f907ed884f27b20fa2408b1c03ce4238f6419eab55f_251c9bf5a7a8402e672a015b823c53b90d3ee8694e05b844fbeb971813405cdf
Pages Built: 39
Cache Status: Miss (created new cache)
```

**Test 2**: Build with hugo-templates content (64 MD files)

```bash
Content: hugo-templates/docs
Command: scripts/build.sh --content ./docs
Cache: Enabled
```

**Result**:
```
Cache Key: build_a121501bcd7fda5a9ecaff521a658fd463c564d5961e52f46dd7545e233b4fb5_cc5cb0a71f553b2fb3428f907ed884f27b20fa2408b1c03ce4238f6419eab55f_251c9bf5a7a8402e672a015b823c53b90d3ee8694e05b844fbeb971813405cdf
Cache Status: Miss (but key IDENTICAL to Test 1!)
Build: Failed (shortcode error - secondary issue)
```

## 📊 Comparative Analysis

| Metric | Test 1 (info-tech) | Test 2 (hugo-templates) | Expected Behavior |
|--------|-------------------|------------------------|-------------------|
| Content Files | 14 MD files | 64 MD files | Different |
| Content Path | `./module-content/content` | `./docs` | **Different** |
| Cache Key | `build_a12150...` | `build_a12150...` | ✅ **Should differ** |
| Key Match | - | ❌ **IDENTICAL** | Should be different! |

## 🐛 Bug Confirmation

### Evidence

**Cache Key Identical Despite Different Content**:
```
Test 1 content: ./module-content/content (14 MD)
Test 1 key:     build_a121501bcd7f...251c9bf5...405cdf

Test 2 content: ./docs (64 MD)
Test 2 key:     build_a121501bcd7f...251c9bf5...405cdf
                ^^^^^^^^^^^^^^^^^ IDENTICAL ^^^^^^^^^^^
```

### Root Cause Analysis

**File**: `scripts/build.sh`

**Lines 729** (in `check_build_cache()` function):
```bash
config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}" | sha256sum | cut -d' ' -f1)
#                                                                                    ^^^^^^^^
#                                                                       MISSING: ${CONTENT}
```

**Lines 768** (in `store_build_cache()` function):
```bash
config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}" | sha256sum | cut -d' ' -f1)
#                                                                                    ^^^^^^^^
#                                                                       MISSING: ${CONTENT}
```

**Problem**: The `$CONTENT` variable is not included in `config_hash` calculation, causing:
1. Builds with different `--content` parameters generate identical cache keys
2. Cache hits occur even when content source changes
3. Wrong content is served from cache

## ✅ Success Criteria Verification

### Mandatory Requirements
- [x] **GitHub Pages workflow functional** - Found in `info-tech-io.github.io`
- [x] **Workaround confirmed** - Production uses `--no-cache` flag
- [x] **Bug reproduced** - Cache keys identical for different content
- [x] **Root cause identified** - `$CONTENT` missing from config_hash
- [x] **Observable difference** - Cache key analysis provides clear evidence

### Evidence Requirements
- [x] Workflow run links ([#18221608898](https://github.com/info-tech-io/info-tech-io.github.io/actions/runs/18221608898), [#18221800796](https://github.com/info-tech-io/info-tech-io.github.io/actions/runs/18221800796))
- [x] Cache key comparison (identical keys documented above)
- [x] Code inspection (lines 729, 768 identified)
- [x] Test infrastructure (workflow created and committed)

## 🔄 Execution Timeline

| Step | Description | Status | Duration | Notes |
|------|-------------|--------|----------|-------|
| Step 1 | Locate GitHub Pages workflow | ✅ COMPLETE | 5 min | Found in info-tech-io.github.io |
| Step 2 | Create test workflow | ✅ COMPLETE | 20 min | 2 commits, full test infrastructure |
| Step 3 | Execute Test 1 (info-tech) | ✅ COMPLETE | 2 min | 39 pages, cache key captured |
| Step 4 | Execute Test 2 (hugo-templates) | ✅ COMPLETE | 2 min | Identical cache key - BUG CONFIRMED |
| Step 5 | Code inspection | ✅ COMPLETE | 5 min | Lines 729, 768 identified |
| **Total** | **Stage 1 Execution** | ✅ COMPLETE | **~35 min** | Bug reproduced and analyzed |

## 📁 Evidence Collected

### Workflow Runs
- **Test Workflow**: `info-tech-io.github.io/.github/workflows/test-cache-bug.yml`
- **Run #18221608898**: info-tech content, cache enabled
  - Link: https://github.com/info-tech-io/info-tech-io.github.io/actions/runs/18221608898
  - Cache Key: `build_a121501bcd7f...405cdf`
  - Result: 39 pages built

- **Run #18221800796**: hugo-templates content, cache enabled
  - Link: https://github.com/info-tech-io/info-tech-io.github.io/actions/runs/18221800796
  - Cache Key: `build_a121501bcd7f...405cdf` (IDENTICAL)
  - Result: Build failed (shortcode error), but key confirmed identical

### Code References
- **Cache key generation**: `scripts/build.sh:729` (check_build_cache)
- **Cache key generation**: `scripts/build.sh:768` (store_build_cache)
- **Content parameter parsing**: `scripts/build.sh:961-963`
- **Content variable initialization**: `scripts/build.sh:57`

### Commits
- `3df8c36` - Created test workflow for bug reproduction
- `1c7a736` - Added content source selection capability

## 🚧 Issues Encountered

### Issue 1: GitHub Actions Cache Isolation

**Problem**: Each workflow run has isolated cache, preventing direct cache hit demonstration

**Impact**: Could not demonstrate cache serving wrong content in single test sequence

**Workaround**: Analyzed cache keys instead - proved keys are identical for different content

**Resolution**: Cache key analysis provides sufficient proof of bug

### Issue 2: Hugo Shortcode Error in Test 2

**Problem**: Build with hugo-templates/docs failed due to missing quiz shortcode

```
Error: template for shortcode "quiz" not found
```

**Impact**: Could not complete full build comparison

**Mitigation**: Cache key was captured before build failure, confirming bug

**Note**: This is a secondary issue, not related to caching bug

## 📝 Key Findings

### Bug Reproduced?
- [x] **YES** - Bug confirmed through cache key analysis

### Evidence Type
- ✅ **Code Inspection**: Lines 729, 768 missing `$CONTENT` variable
- ✅ **Cache Key Analysis**: Identical keys for different content sources
- ✅ **Production Workaround**: `--no-cache` flag used in deploy-corporate.yml

### Hypothesis Support

From `design.md`, ranked by probability:

1. **Hypothesis #1** (Cache key missing `$CONTENT`): ✅ **CONFIRMED**
   - Evidence: Lines 729, 768 do not include `$CONTENT` in config_hash
   - Cache keys identical despite different `--content` values
   - Direct code inspection confirms hypothesis

2. **Hypothesis #2** (Content hash not recalculated): ⏸️ **NOT TESTED**
   - Not needed - Hypothesis #1 fully explains the bug

3. **Hypothesis #3** (Cache restoration timing): ⏸️ **NOT TESTED**
   - Not needed - Hypothesis #1 fully explains the bug

4. **Hypothesis #4** (Content variable overwrite): ⏸️ **NOT TESTED**
   - Not needed - Hypothesis #1 fully explains the bug

5. **Hypothesis #5** (Cache invalidation bug): ⏸️ **NOT TESTED**
   - Not needed - Hypothesis #1 fully explains the bug

**Conclusion**: Hypothesis #1 (90% probability) is **CONFIRMED**. No need to test remaining hypotheses.

## 🎯 Next Steps

### Immediate Actions
1. ✅ Stage 1 complete - bug reproduced and root cause identified
2. 📝 Create Stage 2 plan: `002-fix-implementation.md`
3. 🔧 Implement fix: Add `${CONTENT}` to config_hash calculation (lines 729, 768)
4. ✅ Test fix: Verify cache keys differ for different content sources

### Fix Implementation Preview

**File**: `scripts/build.sh`

**Change Required** (lines 729 and 768):
```bash
# BEFORE (buggy):
config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}" | sha256sum | cut -d' ' -f1)

# AFTER (fixed):
config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}_${CONTENT}" | sha256sum | cut -d' ' -f1)
#                                                                                    ^^^^^^^^^^^^ ADDED
```

**Expected Impact**:
- Different `--content` values will generate different cache keys
- Cache will properly invalidate when content source changes
- No performance degradation (cache still functional)

## 🔗 References

- **Stage Plan**: [001-reproduction.md](./001-reproduction.md)
- **Design Document**: [design.md](./design.md)
- **Overall Progress**: [progress.md](./progress.md)
- **GitHub Issue**: [#14](https://github.com/info-tech-io/hugo-templates/issues/14)
- **Test Workflow**: [test-cache-bug.yml](https://github.com/info-tech-io/info-tech-io.github.io/blob/main/.github/workflows/test-cache-bug.yml)
- **Workflow Run 1**: [#18221608898](https://github.com/info-tech-io/info-tech-io.github.io/actions/runs/18221608898)
- **Workflow Run 2**: [#18221800796](https://github.com/info-tech-io/info-tech-io.github.io/actions/runs/18221800796)

## 📊 Stage Metrics

- **Execution Time**: 35 minutes
- **Tests Performed**: 2 workflow runs
- **Evidence Pieces**: 4 (code inspection, 2 workflow runs, cache key comparison)
- **Bug Confirmed**: ✅ YES
- **Root Cause Identified**: ✅ YES (`$CONTENT` missing from config_hash)
- **Hypothesis Verified**: ✅ Hypothesis #1 confirmed

---

**Stage Status**: ✅ **COMPLETE** - Bug reproduced, root cause identified
**Next**: Create Stage 2 plan (`002-fix-implementation.md`) and implement fix
