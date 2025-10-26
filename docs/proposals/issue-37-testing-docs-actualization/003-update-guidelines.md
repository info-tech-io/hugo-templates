# Stage 3: Update Testing Guidelines

**Objective**: Document new testing patterns and helpers from Issues #31, #32

**Duration**: 20 minutes

**Dependencies**: Stage 1 complete

---

## Detailed Steps

### Step 3.1: Add Graceful Error Handling Pattern Section

**Action**: Document the graceful error handling pattern from Issue #31

**File**: `docs/content/developer-docs/testing/guidelines.md`

**Content to Add**:
```markdown
## Graceful Error Handling Pattern

Since Child #20 (Testing Infrastructure), our build system supports graceful error handling where builds can complete with `exit 0` even when errors occur, with errors reported in structured logs.

**When to Use**:
- Tests that verify error detection and reporting
- Tests where build may fail or succeed depending on environment
- Integration tests that check structured logging

**Pattern**:
\`\`\`bash
# Accept either hard failure OR graceful completion with error logs
if [ "$status" -ne 0 ]; then
    # Hard failure - check output
    assert_contains "$output" "error message"
else
    # Graceful completion - check structured logs
    assert_log_message "$output" "error message" "ERROR"
fi
\`\`\`

**Reference**: Issue #31
```

**Verification**:
- [ ] Section added with clear explanation
- [ ] Code example included
- [ ] Issue #31 referenced

---

### Step 3.2: Add Test Isolation Pattern Section

**Action**: Document the test isolation pattern from Issue #32

**Content to Add**:
```markdown
## Test Isolation Pattern

Tests must work with isolated copies in `$TEST_TEMP_DIR`, never modifying real project files.

**Key Variables**:
- `$TEST_TEMP_DIR` - Isolated test directory in `/tmp`
- `$TEST_TEMPLATES_DIR` - Isolated template copies
- `$ORIGINAL_PROJECT_ROOT` - Path to real project (for reference only)

**Pattern**:
\`\`\`bash
# ✅ CORRECT - Use isolated directories
run ls "$TEST_TEMPLATES_DIR/minimal"

# ❌ WRONG - Don't modify real project
run ls "$PROJECT_ROOT/templates/minimal"
\`\`\`

**Reference**: Issue #32
```

**Verification**:
- [ ] Section added
- [ ] Variables documented
- [ ] Examples show correct pattern

---

### Step 3.3: Document assert_log_message() Helper

**Action**: Add documentation for assert_log_message() helper from Issue #31

**Content to Add**:
```markdown
## Helper Functions

### assert_log_message()

Asserts that a log message exists in structured logging output.

**Signature**:
\`\`\`bash
assert_log_message "$output" "message" "LOG_LEVEL"
\`\`\`

**Arguments**:
- `$1` - Output to search (typically `$output` from BATS `run`)
- `$2` - Expected message content (substring match)
- `$3` - Expected log level (INFO|SUCCESS|WARN|ERROR|FATAL) [optional]

**Example**:
\`\`\`bash
run ./scripts/build.sh --list-templates
assert_log_message "$output" "Available templates" "INFO"
\`\`\`

**Reference**: Issue #31
```

**Verification**:
- [ ] Function signature documented
- [ ] Arguments explained
- [ ] Example provided

---

### Step 3.4: Add CI-Specific Considerations Section

**Action**: Document CI-specific testing considerations from Issue #35

**Content to Add**:
```markdown
## CI-Specific Considerations

### Environment Differences

CI environment (GitHub Actions) differs from local environment:
- Templates are pre-created in CI setup
- Error tests must explicitly specify `--template nonexistent`
- Output annotations limited to 1000 lines (increased from 500 in Issue #35)

### CI Best Practices

**Explicit Template Specification**:
\`\`\`bash
# For error tests, explicitly specify non-existent template
run "$SCRIPT_DIR/build.sh" \\
    --template nonexistent \\
    --config "$config_file"
\`\`\`

**Reference**: Issue #35
```

**Verification**:
- [ ] CI differences explained
- [ ] Output limit documented (1000 lines)
- [ ] Best practices included

---

## Definition of Done

- [ ] Graceful error handling pattern documented
- [ ] Test isolation pattern documented
- [ ] `assert_log_message()` helper documented
- [ ] CI-specific considerations documented
- [ ] All code examples tested and accurate
- [ ] Issues #31, #32, #35 referenced
- [ ] File saves successfully

---

## Estimated Time: 20 minutes
