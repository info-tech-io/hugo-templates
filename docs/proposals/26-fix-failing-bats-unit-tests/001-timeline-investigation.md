# Stage 1: Timeline Investigation

**Objective**: Identify when BATS tests were created and when they started failing
**Duration**: Estimated 1 hour
**Dependencies**: None

## Detailed Steps

### Step 1.1: Find Test Creation Timeline

**Action**: Locate when BATS unit tests were created in the repository

**Implementation**:
```bash
# Find when test files were added
git log --diff-filter=A --find-renames=100% --format="%h %aI %s" -- tests/bash/unit/*.bats

# Check Epic #2 (Build System v2.0) for test creation
git log --oneline --grep="test" epic/build-system-v2.0 | head -20

# Review test-bash.sh creation
git log --format="%h %aI %s" -- scripts/test-bash.sh | head -10
```

**Verification**:
- [ ] Identified commit hash where tests were added
- [ ] Confirmed which Epic created these tests (likely Epic #2)
- [ ] Documented test creation date

**Success Criteria**:
- ✅ Exact commit and date when tests were created
- ✅ Understanding of original test purpose

### Step 1.2: Review Epic #2 Progress Reports

**Action**: Check Epic #2 documentation to understand test context

**Implementation**:
```bash
# List Epic #2 proposal files
find docs/proposals/epic-2-build-system-v2-0 -name "*.md" | sort

# Review Child Issue #4 (Test Coverage Framework) - likely source
cat docs/proposals/epic-2-build-system-v2-0/child-4-test-coverage-framework/design.md
cat docs/proposals/epic-2-build-system-v2-0/child-4-test-coverage-framework/progress.md
```

**Verification**:
- [ ] Read Child #4 (Test Coverage) design and progress
- [ ] Identified what tests were supposed to do
- [ ] Confirmed tests were passing when created

**Success Criteria**:
- ✅ Understanding of test expectations
- ✅ Confirmation tests passed in Epic #2

### Step 1.3: Check Epic #15 Child Issues for Breaking Changes

**Action**: Review each Epic #15 child issue to find when tests started failing

**Implementation**:
```bash
# Child #16: Federated Build Script Foundation
cat docs/proposals/epic-15-federated-build-system/child-1-federated-build-script/001-progress.md
cat docs/proposals/epic-15-federated-build-system/child-1-federated-build-script/002-progress.md
cat docs/proposals/epic-15-federated-build-system/child-1-federated-build-script/003-progress.md

# Child #17: Modules.json Schema
cat docs/proposals/epic-15-federated-build-system/child-2-modules-json-schema/001-progress.md
cat docs/proposals/epic-15-federated-build-system/child-2-modules-json-schema/002-progress.md

# Child #18: CSS Path Resolution
cat docs/proposals/epic-15-federated-build-system/child-3-css-path-resolution/001-progress.md
cat docs/proposals/epic-15-federated-build-system/child-3-css-path-resolution/002-progress.md

# Look for mentions of test failures
grep -r "test.*fail" docs/proposals/epic-15-federated-build-system/child-*/
grep -r "BATS" docs/proposals/epic-15-federated-build-system/child-*/
```

**Verification**:
- [ ] Reviewed all child issue progress reports
- [ ] Identified mentions of test failures
- [ ] Found commit where tests started failing

**Success Criteria**:
- ✅ Timeline of when tests broke
- ✅ Which child issue introduced the breaking change

### Step 1.4: Test Each Commit Range

**Action**: Checkout commits and run tests to pinpoint exact failure point

**Implementation**:
```bash
# Get commit history for epic branch
git log --oneline epic/federated-build-system | head -30

# Test at key checkpoints:
# 1. Before Child #16
# 2. After Child #16 merge
# 3. After Child #17 merge
# 4. After Child #18 merge

# For each checkpoint:
git checkout <commit-hash>
./scripts/test-bash.sh --suite unit --verbose 2>&1 | grep -E "(PASS|FAIL|Summary)"
```

**Verification**:
- [ ] Tested at main branch (baseline)
- [ ] Tested after each child issue merge
- [ ] Identified exact commit where tests failed
- [ ] Documented which changes caused failures

**Success Criteria**:
- ✅ Exact commit hash where tests started failing
- ✅ Specific changes that caused failures

### Step 1.5: Document Timeline and Changes

**Action**: Create comprehensive timeline document

**Implementation**:
Create a timeline document showing:
- Test creation: commit hash, date, Epic #2 context
- Test status at Epic #15 start: passing/failing
- Each child issue merge: commit hash, test status
- Breaking commit: exact hash, changes made
- Current status: number of failures, error types

**Verification**:
- [ ] Timeline document created
- [ ] All key dates and commits documented
- [ ] Changes analysis included

**Success Criteria**:
- ✅ Complete timeline from test creation to current state
- ✅ Clear identification of breaking changes

## Testing Plan

### Verification Steps

1. **Git History Accuracy**:
   - Verify commit hashes are correct
   - Confirm dates match git log output
   - Validate branch relationships

2. **Test Execution Verification**:
   - Run tests at identified commits
   - Verify pass/fail status matches documentation
   - Document exact error messages

3. **Documentation Completeness**:
   - All commits identified
   - All dates recorded
   - All changes documented

## Expected Outputs

1. **Timeline Document** (`001-progress.md` update):
   - Test creation: commit, date, Epic
   - Test status history
   - Breaking change identification

2. **Changes Analysis**:
   - What changed in breaking commit
   - Why it might affect tests
   - Potential fix strategies

## Definition of Done

- [ ] All steps completed
- [ ] Timeline documented
- [ ] Breaking commit identified
- [ ] Changes analyzed
- [ ] 001-progress.md updated
- [ ] Ready for Stage 2 (Root Cause Analysis)

---

**Estimated Time**: 1 hour
**Actual Time**: TBD
**Status**: ⏳ Ready to start
