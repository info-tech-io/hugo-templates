# Issue #32: Test Isolation - Progress Tracking

**Issue**: https://github.com/info-tech-io/hugo-templates/issues/32
**Status**: 🔄 **IN PROGRESS**
**Branch**: `bugfix/test-isolation`
**Created**: 2025-10-24
**Updated**: 2025-10-24

---

## Overview

Fix test infrastructure to work with isolated temporary copies instead of modifying real project files. This eliminates test artifacts in the working directory and ensures true test isolation.

**Goal**: Clean `git status` after test runs, 185/185 tests passing ✅

---

## Current Status

### Before Fix

```bash
git status --short
# Output:
 m components/quiz-engine
 M templates/corporate/README.md
 M templates/corporate/components.yml
 M templates/corporate/content/_index.md
 M templates/minimal/content/_index.md
 M templates/minimal/hugo.toml
 m themes/compose
?? templates/empty-files-template/
?? templates/integration-test/
?? templates/minimal/test.txt
?? templates/space-files-template/
?? themes/test-theme/
```

### Target After Fix

```bash
git status
# Output:
On branch bugfix/test-isolation
nothing to commit, working tree clean ✅
```

---

## Implementation Stages

### Stage 1: Update Test Helpers ⏳
**Status**: PENDING
**Duration**: ~10 minutes
**File**: `tests/bash/helpers/test-helpers.bash`

**Tasks**:
- [ ] 1.1: Update `setup_test_environment()` to create `$TEST_TEMPLATES_DIR`
- [ ] 1.2: Update `setup_test_environment()` to create `$TEST_THEMES_DIR`
- [ ] 1.3: Update `create_test_template_structure()` to use isolated directories
- [ ] 1.4: Test helper functions work correctly
- [ ] 1.5: Commit: `test: add isolated template directory support`

**Deliverable**: Test helpers support isolated template/theme directories (~20 lines)

---

### Stage 2: Update Integration Tests ⏳
**Status**: PENDING
**Duration**: ~10 minutes
**Dependencies**: Stage 1 ✅
**Files**:
- `tests/bash/integration/full-build-workflow.bats`
- `tests/bash/integration/enhanced-features-v2.bats`
- `tests/bash/integration/error-scenarios.bats`

**Tasks**:
- [ ] 2.1: Update `full-build-workflow.bats` (~15 path references)
- [ ] 2.2: Update `enhanced-features-v2.bats` (~10 path references)
- [ ] 2.3: Update `error-scenarios.bats` (~8 path references)
- [ ] 2.4: Run integration test suite to verify
- [ ] 2.5: Commit: `test: update integration tests to use isolated templates`

**Deliverable**: All integration tests use `$TEST_TEMPLATES_DIR` (~33 lines modified)

---

### Stage 3: Update Unit Tests and Verify ⏳
**Status**: PENDING
**Duration**: 5-10 minutes
**Dependencies**: Stage 2 ✅
**File**: `tests/bash/unit/build-functions.bats`

**Tasks**:
- [ ] 3.1: Update `build-functions.bats` (~5 path references)
- [ ] 3.2: Run full test suite: `./scripts/test-bash.sh`
- [ ] 3.3: Verify 185/185 tests passing
- [ ] 3.4: Clean up existing test artifacts from working directory
- [ ] 3.5: Verify `git status` is clean
- [ ] 3.6: Run tests again to confirm repeatability
- [ ] 3.7: Commit: `test: update unit tests to use isolated templates`

**Deliverable**: All tests passing, clean git status ✅

---

## Progress Metrics

### Overall Completion: 0% (0/3 stages complete) ⏳

| Stage | Status | Progress | Duration | Files Modified |
|-------|--------|----------|----------|----------------|
| Stage 1: Test Helpers | ⏳ Pending | 0% | ~10 min | 1 |
| Stage 2: Integration Tests | ⏳ Pending | 0% | ~10 min | 3 |
| Stage 3: Unit Tests + Verify | ⏳ Pending | 0% | ~5-10 min | 1 |

**Total Files to Modify**: 5
**Total Lines Expected**: ~58 lines modified/added

---

## Timeline

### Estimated Timeline
- **Total Estimated**: 25-30 minutes
- **Stage 1**: 10 minutes
- **Stage 2**: 10 minutes
- **Stage 3**: 5-10 minutes

### Actual Timeline
- **Started**: 2025-10-24
- **Completed**: Not yet started
- **Total Duration**: TBD

---

## Test Pass Rate Progress

### Current State
```
Total Tests: 185
Passing: 185 (100%)
Failing: 0 (0%)
Git Status: DIRTY ❌ (test artifacts present)
```

### Target State
```
Total Tests: 185
Passing: 185 (100%) ✅
Failing: 0 (0%) ✅
Git Status: CLEAN ✅ (no test artifacts)
```

---

## Files Modified

### Test Infrastructure
- [ ] `tests/bash/helpers/test-helpers.bash` (~20 lines)

### Integration Tests
- [ ] `tests/bash/integration/full-build-workflow.bats` (~15 lines)
- [ ] `tests/bash/integration/enhanced-features-v2.bats` (~10 lines)
- [ ] `tests/bash/integration/error-scenarios.bats` (~8 lines)

### Unit Tests
- [ ] `tests/bash/unit/build-functions.bats` (~5 lines)

**Total Changes**: ~58 lines modified

---

## Commits

### Planned Commits (3 total)
1. ⏳ `test: add isolated template directory support`
2. ⏳ `test: update integration tests to use isolated templates`
3. ⏳ `test: update unit tests to use isolated templates`

### Actual Commits
- None yet

---

## Artifacts to Clean Up

### Untracked Files
- [ ] `templates/integration-test/`
- [ ] `templates/empty-files-template/`
- [ ] `templates/space-files-template/`
- [ ] `templates/minimal/test.txt`
- [ ] `themes/test-theme/`

### Modified Files
- [ ] `templates/corporate/README.md`
- [ ] `templates/corporate/components.yml`
- [ ] `templates/corporate/content/_index.md`
- [ ] `templates/minimal/content/_index.md`
- [ ] `templates/minimal/hugo.toml`

### Modified Submodules
- [ ] `components/quiz-engine`
- [ ] `themes/compose`

---

## Blockers

**Current Blockers**: None

**Potential Blockers**:
- None anticipated (straightforward path replacements)

---

## Success Criteria

### Functional
- [ ] All 185 tests pass (100%)
- [ ] No test artifacts in working directory
- [ ] Clean `git status` after test runs
- [ ] Tests use `$TEST_TEMPLATES_DIR` instead of `$PROJECT_ROOT/templates`
- [ ] Tests use `$TEST_THEMES_DIR` instead of `$PROJECT_ROOT/themes`

### Code Quality
- [ ] Helper functions follow existing patterns
- [ ] Path references consistent throughout
- [ ] No hardcoded paths in tests
- [ ] Backward compatible (no test API changes)

### Testing
- [ ] Full test suite passes: `./scripts/test-bash.sh` (185/185)
- [ ] Multiple test runs don't accumulate artifacts
- [ ] Clean git status verified after multiple runs

### Documentation
- [ ] Design document complete ✅
- [ ] Progress tracking maintained
- [ ] Clear commit messages

---

## Commands

### Check Current Status

```bash
# Check git status (see test artifacts)
git status

# Run full test suite
./scripts/test-bash.sh

# Count test results
./scripts/test-bash.sh 2>&1 | grep -c "^ok"
```

### Clean Up Artifacts (Stage 3)

```bash
# Remove untracked test directories
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

# Reset submodules
git submodule update --recursive
```

### Git Workflow

```bash
# Create branch
git checkout -b bugfix/test-isolation

# Commit after each stage
git add tests/bash/helpers/test-helpers.bash
git commit -m "test: add isolated template directory support"

# Push to remote
git push origin bugfix/test-isolation

# Create PR
gh pr create --base epic/federated-build-system \
  --title "fix: isolate tests to prevent modifying project files" \
  --body "Fixes #32"
```

---

## Next Actions

### Immediate Next Steps
1. ⏳ Create branch: `bugfix/test-isolation`
2. ⏳ Start Stage 1: Update test helpers
3. ⏳ Update `setup_test_environment()`
4. ⏳ Update `create_test_template_structure()`
5. ⏳ Test and commit Stage 1

### Current Focus
- Stage 1 pending start

---

## Notes

### Why This Fix is Needed
- Tests currently modify real project files
- Test artifacts clutter working directory
- Risk of committing test files to repository
- Violates testing best practices (isolation)
- Can cause CI/CD issues

### Why This is Important
- Clean development environment
- Professional code quality
- Safer parallel test execution
- Better developer experience
- Prevents accidental commits of test artifacts

### Impact
- **Before**: Dirty git status after tests, artifacts everywhere ❌
- **After**: Clean git status, fully isolated tests ✅
- **Improvement**: True test isolation, zero artifacts

---

**Last Updated**: 2025-10-24
**Status**: ⏳ **READY TO START**
**Next Action**: Create branch `bugfix/test-isolation` and start Stage 1
**Branch**: `bugfix/test-isolation` (to be created)
**Target PR**: `bugfix/test-isolation` → `epic/federated-build-system`

---

## Stage Completion Progress

```
[░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 0% (0/3 stages)

⏳ Stage 1: Test Helpers (Pending)
⏳ Stage 2: Integration Tests (Pending)
⏳ Stage 3: Unit Tests + Verify (Pending)
```
