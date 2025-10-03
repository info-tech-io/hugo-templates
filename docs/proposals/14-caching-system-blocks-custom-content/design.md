# Issue #14: Caching System Blocks Custom Content Processing

**Type**: Bug Fix
**Priority**: Critical
**Status**: Investigation
**Created**: October 2, 2025
**Related Issue**: [#14](https://github.com/info-tech-io/hugo-templates/issues/14)

## Problem Statement

The Hugo Templates Framework caching system interferes with custom content processing when using the `--content` parameter. When caching is enabled (default), builds fall back to template placeholder content instead of processing the specified custom content directory.

### Observed Behavior

**With Cache Enabled** (Default):
```bash
scripts/build.sh --config ./module.json --content ./custom-content --output ./build-output
```
- Generates only **4 pages** (76KB total)
- Contains template RSS/XML feeds
- Missing custom pages and site structure
- **Wrong content served**

**With Cache Disabled** (Workaround):
```bash
scripts/build.sh --config ./module.json --content ./custom-content --output ./build-output --no-cache
```
- Generates **370+ pages** (9.7MB total)
- All custom content properly processed
- Complete site structure
- **Correct content served**

### Impact Assessment

| Severity | Impact |
|----------|--------|
| **Production Blocker** | ✅ Prevents deployment of custom content sites |
| **Silent Failure** | ✅ Builds succeed but serve wrong content |
| **Performance Impact** | ✅ Forces `--no-cache` workaround (slower builds) |
| **User Experience** | ✅ Inconsistent behavior between cached/non-cached |

**Affected Workflows**:
- InfoTech.io corporate site deployment (GitHub Pages)
- Any custom content deployment via `--content` parameter
- CI/CD pipelines relying on cache for performance

## Initial Analysis

### Code Inspection Findings

**Location**: `scripts/build.sh` lines 729, 768

**Current Cache Key Generation**:
```bash
config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}" | sha256sum | cut -d' ' -f1)
```

**Observation**: The `$CONTENT` variable is **NOT included** in cache key generation.

### Systematic Testing Results

From Issue #14 description:

| Scenario | Cache | --content | Result |
|----------|-------|-----------|--------|
| Baseline | Enabled | Present | ❌ Template only (4 pages) |
| Workaround | Disabled | Present | ✅ Full content (370+ pages) |
| Test 1 | Enabled | Present | ❌ Template only |
| Test 2 | Disabled | Present | ✅ Full content |

**Pattern**: Cache enabled → Always serves template content, ignoring `--content` parameter.

## Hypothesis Analysis

### Hypothesis Ranking

Listed in order of decreasing probability based on code inspection and observed symptoms:

#### 1. Cache Key Missing Content Parameter (90% probability) 🔴 **MOST LIKELY**

**Theory**: Cache key doesn't include `$CONTENT` variable, causing cache hits for different content sources.

**Evidence**:
- ✅ Line 729: `config_hash` excludes `$CONTENT`
- ✅ Line 768: Same exclusion in store operation
- ✅ Changing `--content` doesn't invalidate cache
- ✅ `--no-cache` immediately fixes the issue

**Verification Plan**:
1. Inspect cache key generation code (lines 725-735, 764-774)
2. Add debug logging to capture cache keys
3. Test with different `--content` values
4. Verify cache keys are identical despite different content

**Fix Approach** (if confirmed):
```bash
# Add $CONTENT to config_hash
config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}_${CONTENT}" | sha256sum | cut -d' ' -f1)
```

#### 2. Content Hash Not Recalculated (60% probability) 🟡

**Theory**: Template hash calculation doesn't consider content directory, even if content path is passed.

**Evidence**:
- ⚠️ Line 726: `template_hash` only scans `templates/$TEMPLATE`
- ⚠️ No content directory hashing visible
- ✅ Consistent with cache hit behavior

**Verification Plan**:
1. Check if `template_hash` includes content directory
2. Add logging for hash calculation inputs
3. Test hash stability with content changes

**Fix Approach** (if confirmed):
```bash
# Add content hash if content directory specified
if [[ -n "$CONTENT" && -d "$CONTENT" ]]; then
    local content_hash
    content_hash=$(find "$CONTENT" -type f -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1)
    template_hash="${template_hash}_${content_hash}"
fi
```

#### 3. Cache Restoration Timing Issue (40% probability) 🟢

**Theory**: Cache restoration happens BEFORE content copying, so cached output lacks custom content.

**Evidence**:
- ⚠️ Need to verify build.sh execution order
- ⚠️ If cache restores entire `$OUTPUT`, it overwrites content
- ✅ Would explain "template only" content in output

**Verification Plan**:
1. Trace execution flow: cache check → content copy → hugo build
2. Check if `cache_retrieve` restores to `$OUTPUT` directly
3. Verify if content copying happens after cache restoration

**Fix Approach** (if confirmed):
- Move cache check AFTER content preparation
- OR: Cache only Hugo build artifacts, not final output
- OR: Invalidate cache when content changes

#### 4. Content Variable Overwrite (20% probability) 🟢

**Theory**: `modules.json` parsing or other config loading overwrites `$CONTENT` variable after cache key generation.

**Evidence**:
- ⚠️ Speculative - need to trace variable lifecycle
- ⚠️ modules.json has content-related fields
- ❌ Less likely given `--no-cache` fixes it immediately

**Verification Plan**:
1. Add debug logging for `$CONTENT` at key points
2. Check modules.json parsing code
3. Verify variable isn't reset after cache key generation

**Fix Approach** (if confirmed):
- Protect `$CONTENT` variable from override
- OR: Re-generate cache key after all config loading

#### 5. Cache Invalidation Logic Bug (10% probability) 🟢

**Theory**: Cache invalidation is broken, never detecting content changes even if properly configured.

**Evidence**:
- ❌ Cache TTL and cleanup logic seem independent
- ❌ Issue is deterministic, not intermittent
- ❌ Less likely given issue description

**Verification Plan**:
1. Review `cache_exists()` logic in `cache.sh`
2. Check TTL validation
3. Test manual cache clearing vs. `--no-cache`

## Investigation Strategy

### Stage 1: Problem Reproduction ✅ Priority

**Objective**: Establish reproducible test case using InfoTech.io corporate site

**Success Criteria**:
- ✅ GitHub Pages workflow runs successfully with `--no-cache`
- ✅ GitHub Pages workflow fails (wrong content) WITH cache
- ✅ Page count difference documented (4 vs 370+)
- ✅ Output size difference documented (76KB vs 9.7MB)
- ✅ Observable evidence captured (screenshots, logs)

**Test Content**: `info-tech` repository corporate site content

**Test Environment**: GitHub Actions workflow for GitHub Pages deployment

### Stage 2: Hypothesis 1 Verification

**If Stage 1 successful**, proceed to verify most likely hypothesis:

**Test Procedure**:
1. Add debug logging to `build.sh` at lines 729, 735, 768, 774
2. Capture cache keys for two builds with different `--content` paths
3. Compare cache keys - they should differ but likely don't
4. If keys are identical → Hypothesis #1 CONFIRMED

**Success Criteria**:
- ✅ Cache keys logged and compared
- ✅ Root cause identified with evidence
- ✅ Fix approach validated

### Stage 3+: Subsequent Hypotheses

Only if Hypothesis #1 is **NOT** confirmed, proceed to next hypothesis with new detailed plan.

## Expected Outcome

**Most Likely Resolution** (Hypothesis #1):
- Add `$CONTENT` to `config_hash` calculation
- Verify cache keys now differ for different content sources
- Test that custom content builds correctly with cache enabled
- Update cache system documentation

**Testing Requirements**:
- Test with multiple content sources
- Test cache hit/miss behavior
- Test GitHub Pages deployment
- Verify performance impact (cache still provides benefits)

## Implementation Plan

### Phase 1: Investigation (Current)
- ✅ Stage 1: Reproduce bug
- ✅ Stage 2: Verify Hypothesis #1
- ⏳ Stage 3+: Check other hypotheses if needed

### Phase 2: Fix Implementation
- Implement verified fix
- Add regression tests
- Update documentation

### Phase 3: Validation
- Test with InfoTech.io corporate site
- Verify GitHub Pages deployment
- Confirm cache performance maintained

## Documentation Structure

```
docs/proposals/14-caching-system-blocks-custom-content/
├── design.md                  # This file - problem analysis
├── 001-reproduction.md        # Stage 1: Detailed reproduction plan
├── 001-progress.md           # Stage 1: Reproduction results
├── 002-hypothesis-1.md       # Stage 2: Hypothesis #1 verification plan
├── 002-progress.md           # Stage 2: Verification results
└── [003+]                    # Additional stages if needed
```

## References

- **Issue**: [#14 Caching system blocks custom content](https://github.com/info-tech-io/hugo-templates/issues/14)
- **Code**: `scripts/build.sh` (cache key generation)
- **Code**: `scripts/cache.sh` (caching system implementation)
- **Related**: Epic #2 Child #7 (Performance Optimization - introduced caching)
- **Test Content**: `info-tech` repository (corporate site)

---

**Status**: 🔍 **INVESTIGATION STARTED** (Stage 1: Reproduction)
**Next**: Create detailed reproduction plan in `001-reproduction.md`
