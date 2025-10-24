# Issue #32: Test Isolation - Design Document

**Issue**: https://github.com/info-tech-io/hugo-templates/issues/32
**Status**: 🔄 IN PROGRESS
**Branch**: `bugfix/test-isolation`
**Created**: 2025-10-24
**Epic**: #15 (Federated Build System)

---

## Problem Statement

### Current Behavior

Integration and unit tests currently modify project files directly instead of working with isolated temporary copies. This leaves test artifacts in the working directory after test runs.

**Root Cause**: The `create_test_template_structure()` function in `tests/bash/helpers/test-helpers.bash` writes directly to `$PROJECT_ROOT/templates/`:

```bash
create_test_template_structure() {
    local template_dir="$1"  # Receives "$PROJECT_ROOT/templates"
    local template_name="${2:-corporate}"

    # ❌ Overwrites real project files!
    echo "# $template_name Template" > "$template_dir/$template_name/README.md"
    # Creates hugo.toml, components.yml, etc.
}
```

### Impact

**Affected Test Files**:
- `tests/bash/integration/full-build-workflow.bats`
- `tests/bash/integration/enhanced-features-v2.bats`
- `tests/bash/integration/error-scenarios.bats`
- `tests/bash/unit/build-functions.bats`

**Files Modified During Tests**:
- `templates/corporate/README.md`
- `templates/corporate/components.yml`
- `templates/corporate/content/_index.md`
- `templates/minimal/hugo.toml`
- `templates/minimal/content/_index.md`

**Artifacts Left Behind**:
- `templates/integration-test/`
- `templates/empty-files-template/`
- `templates/space-files-template/`
- `templates/minimal/test.txt`
- `themes/test-theme/`
- Modified submodules: `components/quiz-engine`, `themes/compose`

### Why This is a Problem

1. ❌ **Dirty git status** after test runs
2. ❌ **Risk of committing test artifacts** to the repository
3. ❌ **Tests not truly isolated** - can interfere with each other
4. ❌ **Potential conflicts** with real development work
5. ❌ **CI/CD issues** - tests leave behind files in clean environments
6. ❌ **Violates testing best practices** - tests should be fully isolated

---

## Proposed Solution

### High-Level Approach

Tests should:
1. ✅ Create isolated copies of templates in `$TEST_TEMP_DIR`
2. ✅ Work only with these temporary copies
3. ✅ Clean up completely in `teardown_test_environment()`
4. ✅ Never modify real project files

### Design Overview

```
Current (BAD):
  Tests → $PROJECT_ROOT/templates → Modifies real files ❌

Proposed (GOOD):
  Tests → $TEST_TEMP_DIR/templates → Isolated copies ✅
```

---

## Implementation Plan

### Stage 1: Update Test Helpers (10 min)

**File**: `tests/bash/helpers/test-helpers.bash`

#### 1.1: Update `setup_test_environment()`

**Add template isolation**:

```bash
setup_test_environment() {
    # ... existing code ...

    # Create isolated template copies
    export TEST_TEMPLATES_DIR="$TEST_TEMP_DIR/templates"
    mkdir -p "$TEST_TEMPLATES_DIR"

    # Copy real templates if they exist
    if [[ -d "$PROJECT_ROOT/templates" ]]; then
        cp -r "$PROJECT_ROOT/templates"/* "$TEST_TEMPLATES_DIR/" 2>/dev/null || true
    fi

    # Create isolated themes directory
    export TEST_THEMES_DIR="$TEST_TEMP_DIR/themes"
    mkdir -p "$TEST_THEMES_DIR"

    # Copy real themes if they exist
    if [[ -d "$PROJECT_ROOT/themes" ]]; then
        cp -r "$PROJECT_ROOT/themes"/* "$TEST_THEMES_DIR/" 2>/dev/null || true
    fi
}
```

**Estimated**: ~15 lines of code

#### 1.2: Update `create_test_template_structure()`

**Change signature and implementation**:

```bash
create_test_template_structure() {
    local template_dir="$1"  # Now receives "$TEST_TEMPLATES_DIR"
    local template_name="${2:-corporate}"

    # ✅ Works with isolated copies only!
    local template_path="$template_dir/$template_name"
    mkdir -p "$template_path/content"

    # Rest of the function unchanged, but now safe
    echo "# $template_name Template" > "$template_path/README.md"
    # ... etc ...
}
```

**Estimated**: Update ~5 lines

**Total Stage 1**: ~20 lines modified/added

---

### Stage 2: Update Integration Tests (10 min)

#### 2.1: Update `full-build-workflow.bats`

**Find and replace**:
- `$PROJECT_ROOT/templates` → `$TEST_TEMPLATES_DIR`
- `$PROJECT_ROOT/themes` → `$TEST_THEMES_DIR`

**Example**:
```bash
# Before
run ls "$PROJECT_ROOT/templates/minimal"

# After
run ls "$TEST_TEMPLATES_DIR/minimal"
```

**Estimated**: ~15 occurrences to update

#### 2.2: Update `enhanced-features-v2.bats`

**Same pattern**:
- `$PROJECT_ROOT/templates` → `$TEST_TEMPLATES_DIR`

**Estimated**: ~10 occurrences to update

#### 2.3: Update `error-scenarios.bats`

**Same pattern**:
- `$PROJECT_ROOT/templates` → `$TEST_TEMPLATES_DIR`

**Estimated**: ~8 occurrences to update

**Total Stage 2**: ~33 lines modified

---

### Stage 3: Update Unit Tests and Verify (5-10 min)

#### 3.1: Update `build-functions.bats`

**Find and replace**:
- `$PROJECT_ROOT/templates` → `$TEST_TEMPLATES_DIR`

**Estimated**: ~5 occurrences to update

#### 3.2: Run Full Test Suite

```bash
./scripts/test-bash.sh
```

**Expected**: 185/185 tests passing ✅

#### 3.3: Verify Clean Git Status

```bash
git status
```

**Expected**: No test artifacts or modified files ✅

#### 3.4: Clean Up Existing Artifacts

```bash
# Remove test artifacts from working directory
rm -rf templates/integration-test/
rm -rf templates/empty-files-template/
rm -rf templates/space-files-template/
rm -f templates/minimal/test.txt
rm -rf themes/test-theme/

# Restore modified files
git checkout templates/corporate/README.md
git checkout templates/corporate/components.yml
git checkout templates/corporate/content/_index.md
git checkout templates/minimal/hugo.toml
git checkout templates/minimal/content/_index.md

# Reset submodules if needed
git submodule update --recursive
```

**Total Stage 3**: ~10 lines modified + cleanup

---

## Files to Modify

### Summary

| File | Category | Changes | Lines |
|------|----------|---------|-------|
| `tests/bash/helpers/test-helpers.bash` | Test Infrastructure | Add isolation support | ~20 |
| `tests/bash/integration/full-build-workflow.bats` | Integration Tests | Update paths | ~15 |
| `tests/bash/integration/enhanced-features-v2.bats` | Integration Tests | Update paths | ~10 |
| `tests/bash/integration/error-scenarios.bats` | Integration Tests | Update paths | ~8 |
| `tests/bash/unit/build-functions.bats` | Unit Tests | Update paths | ~5 |
| **TOTAL** | | | **~58** |

---

## Testing Strategy

### Verification Steps

1. **Run full test suite before changes**:
   ```bash
   ./scripts/test-bash.sh
   # Should show: 185/185 passing
   ```

2. **Check git status before changes**:
   ```bash
   git status
   # Shows test artifacts (the problem we're fixing)
   ```

3. **Apply Stage 1 changes**:
   - Update `setup_test_environment()`
   - Update `create_test_template_structure()`

4. **Apply Stage 2 changes**:
   - Update all integration tests

5. **Apply Stage 3 changes**:
   - Update unit tests

6. **Run full test suite after changes**:
   ```bash
   ./scripts/test-bash.sh
   # Should show: 185/185 passing ✅
   ```

7. **Verify git status after changes**:
   ```bash
   git status
   # Should be clean (no test artifacts) ✅
   ```

8. **Run tests multiple times to confirm**:
   ```bash
   ./scripts/test-bash.sh && ./scripts/test-bash.sh
   # Both runs should be clean ✅
   ```

### Success Criteria

- ✅ All 185 tests passing (100%)
- ✅ No test artifacts in working directory
- ✅ Clean `git status` after test runs
- ✅ Tests can run in parallel without conflicts
- ✅ No modifications to real project files
- ✅ Backward compatible (no changes to test APIs)

---

## Risk Assessment

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Tests fail after changes | Low | Medium | Incremental testing after each stage |
| Path resolution issues | Low | Low | Use absolute paths, test thoroughly |
| Cleanup doesn't work | Very Low | Low | Verify with multiple test runs |
| Performance degradation | Very Low | Low | Copying templates is fast (~ms) |

### Mitigation Strategy

1. **Incremental approach**: Apply changes in 3 stages with testing after each
2. **Git safety**: Create feature branch, can easily revert if needed
3. **Test isolation**: Changes only affect test infrastructure, not production code
4. **Documentation**: Clear progress tracking for debugging

---

## Benefits

### Immediate Benefits

1. ✅ **Clean git status** - No test artifacts cluttering the working directory
2. ✅ **True test isolation** - Tests can't interfere with each other
3. ✅ **Safer development** - No risk of accidentally committing test files
4. ✅ **Better CI/CD** - Tests work correctly in clean environments
5. ✅ **Professional quality** - Follows testing best practices

### Long-Term Benefits

1. ✅ **Parallel test execution** - Tests can run safely in parallel
2. ✅ **Easier debugging** - No confusion about test vs. real files
3. ✅ **Maintainability** - Clear separation of test and production code
4. ✅ **Confidence** - Tests verify real isolation, not accidental state

---

## Timeline

### Estimated Duration: 25-30 minutes

| Stage | Duration | Tasks |
|-------|----------|-------|
| Stage 1: Test Helpers | 10 min | Update setup and create functions |
| Stage 2: Integration Tests | 10 min | Update 3 integration test files |
| Stage 3: Unit Tests + Verify | 5-10 min | Update unit tests, run suite, verify clean |

---

## References

- **Issue**: https://github.com/info-tech-io/hugo-templates/issues/32
- **Discovered**: During Issue #31 pre-PR cleanup
- **Related**: Epic #15 (Testing Infrastructure - Child #20)
- **Testing Best Practices**: Tests should be isolated and leave no artifacts

---

## Commits

### Planned Commits (3 total)

1. `test: add isolated template directory support`
   - Update `setup_test_environment()`
   - Update `create_test_template_structure()`

2. `test: update integration tests to use isolated templates`
   - Update `full-build-workflow.bats`
   - Update `enhanced-features-v2.bats`
   - Update `error-scenarios.bats`

3. `test: update unit tests to use isolated templates`
   - Update `build-functions.bats`
   - Clean up artifacts
   - Verify clean git status

---

**Last Updated**: 2025-10-24
**Status**: 🔄 Ready to implement
**Branch**: `bugfix/test-isolation`
**Target PR**: `bugfix/test-isolation` → `epic/federated-build-system`
