# Stage 4: Update Test Inventory

**Objective**: Add all 52 integration tests to test inventory

**Duration**: 15 minutes

**Dependencies**: Stage 1 complete

---

## Detailed Steps

### Step 4.1: Add Integration Test Suite Section

**Action**: Create new section listing all 52 integration tests

**File**: `docs/content/developer-docs/testing/test-inventory.md`

**Content to Add**:
```markdown
## Integration Test Suite (52 tests)

Integration tests verify end-to-end workflows and cross-component interactions.

### full-build-workflow.bats (~18 tests)
- Complete build workflow tests
- Template selection and processing
- Output directory management
- Build caching tests

### enhanced-features-v2.bats (~20 tests)
- Enhanced error messages
- User-friendly feedback
- Structured logging verification
- Feature interaction tests

### error-scenarios.bats (~14 tests)
- Empty module.json handling
- Malformed components
- Missing Hugo binary
- Multiple simultaneous errors
- Template not found scenarios
```

**Verification**:
- [ ] Section added with 52 tests
- [ ] Tests organized by file
- [ ] Brief descriptions provided

---

### Step 4.2: Update Summary Statistics

**Action**: Update total test count from 78 to 185

**Changes**:
- Current: "Total: 78 tests"
- Update to: "Total: 185 tests (78 unit + 52 integration + 55 federation)"

**Verification**:
- [ ] Summary updated to 185 total
- [ ] Breakdown shows all categories
- [ ] Math is correct (78+52+55=185)

---

## Definition of Done

- [ ] Integration test suite section added
- [ ] All 52 integration tests listed by file
- [ ] Summary statistics updated to 185
- [ ] File saves successfully

---

## Estimated Time: 15 minutes
