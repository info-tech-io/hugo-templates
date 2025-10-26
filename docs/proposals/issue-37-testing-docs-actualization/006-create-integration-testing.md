# Stage 6: Create Integration Testing Guide

**Objective**: Create comprehensive guide for integration testing

**Duration**: 20 minutes

**Dependencies**: Stage 1 complete

---

## Detailed Steps

### Step 6.1: Create New File

**Action**: Create `docs/content/developer-docs/testing/integration-testing.md`

**File Structure**:
```markdown
---
title: "Integration Testing Guide"
description: "Comprehensive guide to writing and running integration tests"
weight: 40
---

# Integration Testing Guide

(Content from steps below)
```

**Verification**:
- [ ] File created
- [ ] Frontmatter correct
- [ ] Weight set appropriately (40)

---

### Step 6.2: Add Overview Section

**Action**: Explain what integration tests are and how they differ from unit tests

**Content**:
```markdown
## Overview

Integration tests verify end-to-end workflows and cross-component interactions. Unlike unit tests that test individual functions, integration tests verify complete processes.

**Test Count**: 52 integration tests (as of 2025-10-26)

**Test Files**:
- `tests/bash/integration/full-build-workflow.bats` (18 tests)
- `tests/bash/integration/enhanced-features-v2.bats` (20 tests)
- `tests/bash/integration/error-scenarios.bats` (14 tests)
```

---

### Step 6.3: Add Test Isolation Section

**Action**: Document how integration tests use isolated environments

**Content**:
```markdown
## Test Isolation

All integration tests run in isolated `/tmp` directories and never modify real project files.

**Key Pattern** (from Issue #32):
- Tests use `$TEST_TEMP_DIR` for all file operations
- Real project files accessed via `$ORIGINAL_PROJECT_ROOT` (read-only)
- Templates copied to `$TEST_TEMPLATES_DIR` before each test

**Example**:
\`\`\`bash
@test "integration test example" {
    # Uses isolated directory
    run "$SCRIPT_DIR/build.sh" \\
        --template corporate \\
        --output "$TEST_OUTPUT_DIR"

    assert_success
}
\`\`\`
```

---

### Step 6.4: Add Graceful Error Handling Section

**Action**: Document graceful error handling pattern for integration tests

**Content**:
```markdown
## Graceful Error Handling

Integration tests support graceful error handling (from Issue #31):

**Pattern**:
\`\`\`bash
# Accept either hard failure or graceful completion
if [ "$status" -ne 0 ]; then
    assert_contains "$output" "error message"
else
    assert_log_message "$output" "error message" "ERROR"
fi
\`\`\`

**When to Use**:
- Error scenario tests
- Build workflow tests
- Environment-dependent tests
```

---

### Step 6.5: Add CI Considerations Section

**Action**: Document CI-specific integration test patterns from Issue #35

**Content**:
```markdown
## CI Considerations

### Environment Differences

GitHub Actions CI pre-creates templates that don't exist locally. Error tests must specify non-existent templates explicitly:

\`\`\`bash
run "$SCRIPT_DIR/build.sh" \\
    --template nonexistent \\  # Forces failure in CI
    --config "$config_file"
\`\`\`

### Output Limits

CI annotations support 1000 lines (increased in Issue #35). Large outputs are truncated.

**Reference**: Issue #35
```

---

### Step 6.6: Add Best Practices Section

**Action**: Document best practices learned from Issues #31, #32, #35

**Content**:
```markdown
## Best Practices

1. **Always use isolated directories** - Never modify `$PROJECT_ROOT` files
2. **Test both success and failure paths** - Use graceful error handling pattern
3. **Specify templates explicitly in CI** - Use `--template nonexistent` for error tests
4. **Check structured logs** - Use `assert_log_message()` for log verification
5. **Keep output under 1000 lines** - Consider CI annotation limits

**References**:
- Issue #31: Graceful error handling
- Issue #32: Test isolation
- Issue #35: CI reliability
```

---

### Step 6.7: Add Examples Section

**Action**: Provide sample integration tests with explanations

**Content**:
```markdown
## Examples

### Example 1: Build Workflow Test
\`\`\`bash
@test "complete build workflow succeeds" {
    run "$SCRIPT_DIR/build.sh" \\
        --template corporate \\
        --output "$TEST_OUTPUT_DIR"

    assert_success
    assert_log_message "$output" "Build completed" "SUCCESS"
    [ -f "$TEST_OUTPUT_DIR/index.html" ]
}
\`\`\`

### Example 2: Error Scenario Test
\`\`\`bash
@test "handles missing template gracefully" {
    run "$SCRIPT_DIR/build.sh" \\
        --template nonexistent \\
        --output "$TEST_OUTPUT_DIR"

    # Graceful error handling
    if [ "$status" -ne 0 ]; then
        assert_contains "$output" "Template not found"
    else
        assert_log_message "$output" "Template not found" "ERROR"
    fi
}
\`\`\`
```

---

## Definition of Done

- [ ] New file created: `integration-testing.md`
- [ ] All 7 sections added (Overview, Isolation, Error Handling, CI, Best Practices, Examples)
- [ ] Code examples tested and accurate
- [ ] Issues #31, #32, #35 referenced
- [ ] File approximately 300 lines
- [ ] Frontmatter correct
- [ ] File saves successfully

---

## Estimated Time: 20 minutes
