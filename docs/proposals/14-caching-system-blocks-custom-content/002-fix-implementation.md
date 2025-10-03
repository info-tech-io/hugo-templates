# Stage 2: Fix Implementation

**Date**: October 3, 2025
**Status**: Planning
**Objective**: Implement fix for cache key generation to include `$CONTENT` parameter

## Overview

Based on Stage 1 findings, this stage implements the fix for Issue #14 by adding the `$CONTENT` variable to cache key generation. The fix is straightforward - add `${CONTENT}` to the `config_hash` calculation in two locations in `scripts/build.sh`.

## Root Cause Recap

**File**: `scripts/build.sh`
**Lines**: 729 (check_build_cache function), 768 (store_build_cache function)

**Problem**: Cache key does not include `$CONTENT` parameter, causing identical cache keys for different content sources.

**Current Code** (buggy):
```bash
config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}" | sha256sum | cut -d' ' -f1)
```

**Fixed Code** (correct):
```bash
config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}_${CONTENT}" | sha256sum | cut -d' ' -f1)
```

## Success Criteria

### Mandatory Requirements

- ✅ **Code modified**: `$CONTENT` added to both cache key generation points
- ✅ **Syntax valid**: Script passes bash syntax check
- ✅ **Cache keys differ**: Different `--content` values produce different cache keys
- ✅ **No regressions**: Existing builds still work correctly
- ✅ **Cache still functional**: Cache continues to provide performance benefits

### Verification Requirements

- ✅ Different content sources generate different cache keys
- ✅ Same content source generates same cache key (cache reuse works)
- ✅ Empty content parameter handled correctly
- ✅ Build output matches content source (no stale cache)

## Implementation Plan

### Step 1: Apply Code Fix

**Objective**: Modify `config_hash` calculation in both functions

**Actions**:

#### 1.1: Fix check_build_cache() function (line 729)

**Location**: `scripts/build.sh:729`

**Current code**:
```bash
local config_hash
config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}" | sha256sum | cut -d' ' -f1)
```

**Change to**:
```bash
local config_hash
config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}_${CONTENT}" | sha256sum | cut -d' ' -f1)
```

**Verification**:
```bash
# Check syntax
bash -n scripts/build.sh

# Verify change applied
grep -n "config_hash.*CONTENT" scripts/build.sh | grep 729
```

#### 1.2: Fix store_build_cache() function (line 768)

**Location**: `scripts/build.sh:768`

**Current code**:
```bash
local config_hash
config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}" | sha256sum | cut -d' ' -f1)
```

**Change to**:
```bash
local config_hash
config_hash=$(echo "${TEMPLATE}_${THEME}_${COMPONENTS}_${MINIFY}_${ENVIRONMENT}_${BASE_URL}_${CONTENT}" | sha256sum | cut -d' ' -f1)
```

**Verification**:
```bash
# Verify change applied
grep -n "config_hash.*CONTENT" scripts/build.sh | grep 768
```

**Success Criteria**:
- [ ] Both functions modified
- [ ] Syntax check passes
- [ ] Changes appear in both line 729 and 768

### Step 2: Verify Fix Locally

**Objective**: Test fix works correctly with different content sources

**Actions**:

#### 2.1: Create test script for cache key verification

**Script**: `/tmp/verify-cache-fix.sh`

```bash
#!/bin/bash
set -e

REPO="/root/info-tech-io/hugo-templates"
cd "$REPO"

echo "=== Cache Key Fix Verification ==="
echo ""

# Source the build.sh to access functions (for testing)
# We'll test by building with different content and checking cache keys

echo "Test 1: Build with content A"
./scripts/build.sh \
  --template corporate \
  --content /tmp/test-content-A \
  --output /tmp/test-output-1 \
  --verbose 2>&1 | grep "Generated cache key" > /tmp/key1.txt || true

echo "Test 2: Build with content B"
./scripts/build.sh \
  --template corporate \
  --content /tmp/test-content-B \
  --output /tmp/test-output-2 \
  --verbose 2>&1 | grep "Generated cache key" > /tmp/key2.txt || true

echo "Test 3: Build with content A again (should match Test 1)"
./scripts/build.sh \
  --template corporate \
  --content /tmp/test-content-A \
  --output /tmp/test-output-3 \
  --verbose 2>&1 | grep "Generated cache key" > /tmp/key3.txt || true

# Extract keys
KEY1=$(cat /tmp/key1.txt | awk '{print $NF}')
KEY2=$(cat /tmp/key2.txt | awk '{print $NF}')
KEY3=$(cat /tmp/key3.txt | awk '{print $NF}')

echo ""
echo "Results:"
echo "Key 1 (content A): $KEY1"
echo "Key 2 (content B): $KEY2"
echo "Key 3 (content A): $KEY3"
echo ""

# Verify keys
if [ "$KEY1" != "$KEY2" ]; then
  echo "✅ PASS: Different content produces different keys"
else
  echo "❌ FAIL: Keys should differ for different content"
  exit 1
fi

if [ "$KEY1" = "$KEY3" ]; then
  echo "✅ PASS: Same content produces same key (cache reuse works)"
else
  echo "❌ FAIL: Keys should match for same content"
  exit 1
fi

echo ""
echo "✅ All tests passed! Fix verified."
```

**Verification**:
- [ ] Different content paths produce different cache keys
- [ ] Same content path produces same cache key
- [ ] No errors during build

#### 2.2: Test with actual content sources

**Test A**: Build with info-tech content
```bash
./scripts/build.sh \
  --template corporate \
  --content /root/info-tech-io/info-tech/docs/content \
  --output /tmp/test-info-tech \
  --verbose
```

**Expected**:
- Cache key includes hash of content path
- Build succeeds
- Cache key logged in output

**Test B**: Build with hugo-templates docs
```bash
./scripts/build.sh \
  --template corporate \
  --content /root/info-tech-io/hugo-templates/docs \
  --output /tmp/test-hugo-docs \
  --verbose
```

**Expected**:
- Cache key DIFFERENT from Test A
- Build succeeds (or fails on shortcode, but key should be logged)
- Observable difference in cache keys

**Verification**:
```bash
# Compare cache keys from both builds
diff <(grep "Generated cache key" /tmp/test-info-tech.log) \
     <(grep "Generated cache key" /tmp/test-hugo-docs.log)
```

**Success Criteria**:
- [ ] Cache keys are different
- [ ] Both keys contain all parameters including content
- [ ] No syntax or runtime errors

### Step 3: Test in Production Environment (GitHub Actions)

**Objective**: Verify fix works in GitHub Pages deployment workflow

**Actions**:

#### 3.1: Update hugo-templates repository

**Steps**:
1. Commit fix to hugo-templates main branch
2. Push to GitHub

**Commit message**:
```
fix(cache): include content parameter in cache key generation

Add $CONTENT variable to config_hash calculation in both
check_build_cache() and store_build_cache() functions.

This ensures cache keys differ when --content parameter changes,
preventing cache hits from serving wrong content.

Root cause: Cache key generation at lines 729 and 768 did not
include CONTENT variable, causing cache to ignore content source
changes.

Fixes #14

Changes:
- scripts/build.sh:729 - Add ${CONTENT} to config_hash
- scripts/build.sh:768 - Add ${CONTENT} to config_hash
```

#### 3.2: Trigger test workflow

**Workflow**: `info-tech-io.github.io/.github/workflows/test-cache-bug.yml`

**Test Sequence**:
1. Run with info-tech content + cache enabled
2. Run with hugo-templates content + cache enabled
3. Compare cache keys from logs

**Expected Results**:
- Different cache keys for different content
- Both builds succeed (or fail independently, not from cache)
- Cache keys visible in workflow logs

**Verification**:
```bash
# Get cache keys from workflow logs
gh run view <run-id-1> --log | grep "Generated cache key"
gh run view <run-id-2> --log | grep "Generated cache key"

# Keys should differ
```

**Success Criteria**:
- [ ] Workflow runs complete
- [ ] Cache keys differ between runs with different content
- [ ] No cache-related errors
- [ ] Fix validated in production environment

### Step 4: Remove Workaround (Optional)

**Objective**: Remove `--no-cache` workaround from production workflow

**File**: `info-tech-io.github.io/.github/workflows/deploy-corporate.yml`

**Change** (lines 75, 78):
```yaml
# BEFORE (with workaround):
scripts/build.sh ... --no-cache

# AFTER (fix applied, workaround removed):
scripts/build.sh ...
```

**Note**: This step is optional and can be done after additional confidence building. Recommend keeping `--no-cache` initially as safety measure.

**Success Criteria**:
- [ ] Production deployment succeeds without `--no-cache`
- [ ] Correct content served (370+ pages for full federation)
- [ ] Cache provides performance improvement
- [ ] No content mismatch issues

## Testing Strategy

### Unit Testing

**Test 1**: Cache key generation with different content paths
```bash
# Expected: Different keys
build.sh --content /path/A  # Key: abc123...
build.sh --content /path/B  # Key: def456...
```

**Test 2**: Cache key generation with same content path
```bash
# Expected: Same key
build.sh --content /path/A  # Key: abc123...
build.sh --content /path/A  # Key: abc123... (identical)
```

**Test 3**: Cache key with empty content
```bash
# Expected: Valid key, different from non-empty
build.sh --content ""       # Key: ghi789...
build.sh --content /path/A  # Key: abc123... (different)
```

### Integration Testing

**Test 4**: Cache hit/miss behavior
```bash
# First build - cache miss
build.sh --content /path/A --output /tmp/out1
# Verify: Cache miss logged, cache created

# Second build - cache hit (same content)
build.sh --content /path/A --output /tmp/out2
# Verify: Cache hit logged, same output

# Third build - cache miss (different content)
build.sh --content /path/B --output /tmp/out3
# Verify: Cache miss logged, different output
```

**Test 5**: Production deployment
```bash
# Deploy with fix applied
# Verify: Correct content served, cache functional
```

## Rollback Plan

If fix causes issues:

1. **Immediate**: Revert commit
   ```bash
   git revert <commit-hash>
   git push origin main
   ```

2. **Temporary**: Keep `--no-cache` workaround in production

3. **Investigation**: Review logs, test locally, identify issue

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Syntax error in fix | Low | High | Bash syntax check before commit |
| Cache invalidation too aggressive | Low | Low | Add tests for cache reuse |
| Performance degradation | Very Low | Medium | Cache still functional, just more specific |
| Breaking existing builds | Very Low | High | Test with multiple content sources |

**Overall Risk**: **Low** - Fix is minimal, well-understood, and thoroughly tested in Stage 1.

## Definition of Done

- [ ] Code modified in both locations (lines 729, 768)
- [ ] Bash syntax check passes
- [ ] Local testing shows different cache keys for different content
- [ ] Local testing shows same cache key for same content
- [ ] Committed with proper message format
- [ ] Pushed to main branch
- [ ] GitHub Actions test workflow validates fix
- [ ] `002-progress.md` updated with results
- [ ] `progress.md` updated with Stage 2 completion

## Expected Timeline

| Step | Duration | Status |
|------|----------|--------|
| Step 1: Apply fix | 5 min | Pending |
| Step 2: Local testing | 15 min | Pending |
| Step 3: Production testing | 10 min | Pending |
| Step 4: Documentation | 10 min | Pending |
| **Total** | **40 min** | Pending |

## References

- **Stage 1 Report**: [001-progress.md](./001-progress.md)
- **Design Document**: [design.md](./design.md)
- **Overall Progress**: [progress.md](./progress.md)
- **GitHub Issue**: [#14](https://github.com/info-tech-io/hugo-templates/issues/14)
- **Saved Fix Patch**: `/tmp/cache-fix.patch` (for reference)

---

**Status**: 📋 **PLAN READY** - Ready for execution
**Next**: Execute fix implementation and document results in `002-progress.md`
