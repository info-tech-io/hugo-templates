# Stage 2: Update Main Testing Index (_index.md)

**Objective**: Update main testing overview page to reflect current test suite state

**Duration**: 15 minutes

**Dependencies**: Stage 1 complete

---

## Detailed Steps

### Step 2.1: Update Test Count Statistics

**Action**: Replace outdated test counts with current statistics

**File**: `docs/content/developer-docs/testing/_index.md`

**Changes**:
- Current: "78 unit tests"
- Update to: "185 total tests (78 unit + 52 integration + 55 federation)"
- Update pass rate to: "100% (185/185 tests passing)"

**Implementation**:
Find and update the test statistics section.

**Verification**:
- [ ] Test count shows 185 total
- [ ] Breakdown shows 78 + 52 + 55
- [ ] Pass rate shows 100% (185/185)

---

### Step 2.2: Add Integration Test Section

**Action**: Add new section describing integration test suite

**Content to Add**:
```markdown
## Integration Test Suite

Our integration test suite consists of 52 tests that verify end-to-end workflows and cross-component interactions.

**Test Files**:
- `tests/bash/integration/full-build-workflow.bats`
- `tests/bash/integration/enhanced-features-v2.bats`
- `tests/bash/integration/error-scenarios.bats`

**Coverage**: Integration tests verify complete build workflows, error handling, and feature interactions.

See [Integration Testing Guide](integration-testing.md) for detailed documentation.
```

**Verification**:
- [ ] Integration section added
- [ ] 52 tests mentioned
- [ ] Link to integration-testing.md added

---

### Step 2.3: Update Links Section

**Action**: Add link to new integration-testing.md file

**Implementation**:
Add to the documentation links section:
```markdown
- [Integration Testing Guide](integration-testing.md) - Comprehensive guide to integration testing patterns
```

**Verification**:
- [ ] Link added
- [ ] Link points to correct file

---

## Definition of Done

- [ ] Test counts updated to 185 total (78 + 52 + 55)
- [ ] Pass rate updated to 100%
- [ ] Integration test section added
- [ ] Link to integration-testing.md added
- [ ] File saves successfully
- [ ] No broken formatting

---

## Estimated Time: 15 minutes
