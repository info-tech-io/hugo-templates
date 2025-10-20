# Stage 1: Create Test Helper Functions

**Objective**: Create reusable helper functions to handle structured logging assertions in tests
**Duration**: 30 minutes
**Dependencies**: None
**File**: `tests/bash/helpers/test-helpers.bash`

---

## Overview

This stage creates two helper functions that will make test assertions resilient to the structured logging format introduced in Child #20. These helpers will be used by all subsequent stages to update the 17 failing integration tests.

---

## Detailed Steps

### Step 1.1: Add `assert_log_message()` Function

**Action**: Create helper function to assert log messages exist while handling structured logging format

**Implementation**:
```bash
# Assert log message exists (handles structured logging format)
#
# Usage:
#   assert_log_message "$output" "Expected message" "INFO"
#   assert_log_message "$output" "Build completed" "SUCCESS"
#
# Arguments:
#   $1 - Output to search (typically $output from BATS run)
#   $2 - Expected message content (substring match)
#   $3 - Expected log level (INFO|SUCCESS|WARN|ERROR|FATAL) [optional]
#
# Returns:
#   0 - Message found with correct log level
#   1 - Message not found or incorrect log level
#
assert_log_message() {
  local output="$1"
  local expected_message="$2"
  local expected_level="${3:-}"  # Optional

  # Strip ANSI escape codes
  local clean_output
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')

  # Strip timestamps (format: [YYYY-MM-DDTHH:MM:SS+00:00])
  clean_output=$(echo "$clean_output" | sed 's/\[[0-9-]*T[0-9:+]*\]//g')

  # Check message exists
  if ! echo "$clean_output" | grep -qF "$expected_message"; then
    echo "Expected message not found: '$expected_message'"
    echo "Actual output (cleaned):"
    echo "$clean_output"
    return 1
  fi

  # Check log level if specified
  if [[ -n "$expected_level" ]]; then
    if ! echo "$clean_output" | grep -qF "[$expected_level]"; then
      echo "Expected log level not found: [$expected_level]"
      echo "Actual output (cleaned):"
      echo "$clean_output"
      return 1
    fi
  fi

  return 0
}
```

**Verification**:
- [ ] Function added to test-helpers.bash
- [ ] JSDoc-style documentation included
- [ ] Function handles ANSI color codes correctly
- [ ] Function handles timestamps correctly
- [ ] Function checks message content
- [ ] Function optionally checks log level

**Success Criteria**:
- ✅ Function properly strips ANSI codes: `\x1b\[[0-9;]*m`
- ✅ Function properly strips timestamps: `[2025-10-20T01:45:44+00:00]`
- ✅ Function finds message content via grep -qF
- ✅ Function validates log level when provided

---

### Step 1.2: Add `assert_log_message_with_category()` Function

**Action**: Create helper function to assert log messages with specific categories

**Implementation**:
```bash
# Assert log message with category
#
# Usage:
#   assert_log_message_with_category "$output" "Build started" "INFO" "BUILD"
#
# Arguments:
#   $1 - Output to search
#   $2 - Expected message content
#   $3 - Expected log level
#   $4 - Expected category
#
# Returns:
#   0 - Message found with correct level and category
#   1 - Message/level/category not found
#
assert_log_message_with_category() {
  local output="$1"
  local expected_message="$2"
  local expected_level="$3"
  local expected_category="$4"

  # First check message and level
  assert_log_message "$output" "$expected_message" "$expected_level" || return 1

  # Then check category
  local clean_output
  clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/\[[0-9-]*T[0-9:+]*\]//g')

  if ! echo "$clean_output" | grep -qF "[$expected_category]"; then
    echo "Expected category not found: [$expected_category]"
    return 1
  fi

  return 0
}
```

**Verification**:
- [ ] Function added to test-helpers.bash
- [ ] JSDoc-style documentation included
- [ ] Function calls `assert_log_message()` first
- [ ] Function validates category in cleaned output
- [ ] Function provides clear error messages

**Success Criteria**:
- ✅ Function reuses `assert_log_message()` for core validation
- ✅ Function additionally checks for category tag like `[BUILD]`
- ✅ Function returns appropriate error code on failure

---

### Step 1.3: Add JSDoc-Style Documentation

**Action**: Ensure both functions have complete documentation headers

**Implementation**:
Documentation already included in Steps 1.1 and 1.2 above.

**Verification**:
- [ ] Each function has comment block
- [ ] Usage examples provided
- [ ] Parameters documented
- [ ] Return values documented
- [ ] Examples show real-world use cases

**Success Criteria**:
- ✅ Documentation follows existing test-helpers.bash style
- ✅ Usage examples are clear and actionable
- ✅ Parameters and return values are explicit

---

### Step 1.4: Test Helpers with Sample Inputs

**Action**: Manually verify helpers work correctly before using in tests

**Implementation**:
```bash
# Create quick test script
cat > /tmp/test-helpers-check.sh << 'EOF'
#!/bin/bash
source tests/bash/helpers/test-helpers.bash

# Test 1: Basic message assertion
output="[0;34m[2025-10-20T01:45:44+00:00] [INFO] [GENERAL] Available templates:[0m"
if assert_log_message "$output" "Available templates" "INFO"; then
  echo "✅ Test 1 passed: Basic message assertion"
else
  echo "❌ Test 1 failed"
  exit 1
fi

# Test 2: Message with category
output="[0;32m[2025-10-20T01:45:44+00:00] [SUCCESS] [BUILD] Build completed successfully![0m"
if assert_log_message_with_category "$output" "Build completed" "SUCCESS" "BUILD"; then
  echo "✅ Test 2 passed: Message with category"
else
  echo "❌ Test 2 failed"
  exit 1
fi

# Test 3: Missing message (should fail)
output="[0;34m[2025-10-20T01:45:44+00:00] [INFO] [GENERAL] Some other message[0m"
if assert_log_message "$output" "Non-existent message" "INFO"; then
  echo "❌ Test 3 failed: Should have failed to find message"
  exit 1
else
  echo "✅ Test 3 passed: Correctly rejected missing message"
fi

echo "✅ All helper tests passed!"
EOF

chmod +x /tmp/test-helpers-check.sh
/tmp/test-helpers-check.sh
```

**Verification**:
- [ ] Test 1 passes: Basic message finding
- [ ] Test 2 passes: Message with category
- [ ] Test 3 passes: Correctly fails for missing message
- [ ] All three tests complete successfully

**Success Criteria**:
- ✅ Helpers correctly strip ANSI codes and timestamps
- ✅ Helpers find expected messages
- ✅ Helpers fail appropriately when message not found

---

### Step 1.5: Commit Changes

**Action**: Commit the new helper functions

**Implementation**:
```bash
git add tests/bash/helpers/test-helpers.bash
git commit -m "test: add structured logging test helpers

- Add assert_log_message() helper for structured logging assertions
- Add assert_log_message_with_category() helper for category validation
- Include JSDoc-style documentation with usage examples
- Helpers strip ANSI codes and timestamps for reliable assertions

These helpers make tests resilient to structured logging format changes
introduced in Child #20 (Testing Infrastructure).

Related: #31, Epic: #15"
```

**Verification**:
- [ ] Changes staged
- [ ] Commit message follows conventional commits format
- [ ] Commit includes reference to Issue #31
- [ ] Commit includes reference to Epic #15

**Success Criteria**:
- ✅ Commit created successfully
- ✅ Commit message is descriptive and follows project standards
- ✅ Changes are properly tracked in git

---

## Testing Plan

### Manual Testing
1. Run helper test script created in Step 1.4
2. Verify all three test cases pass
3. Verify error messages are clear when assertions fail

### Integration Testing
Will be validated in Stage 2 when first tests are updated to use these helpers.

---

## Rollback Plan

If helpers don't work as expected:
```bash
# Revert the commit
git revert HEAD

# Or reset if not pushed
git reset --soft HEAD~1
```

---

## Definition of Done

### Functional
- [ ] `assert_log_message()` function added and documented
- [ ] `assert_log_message_with_category()` function added and documented
- [ ] Both functions handle ANSI codes correctly
- [ ] Both functions handle timestamps correctly
- [ ] Manual testing shows helpers work correctly

### Code Quality
- [ ] Code follows existing test-helpers.bash style
- [ ] Documentation is clear and complete
- [ ] Functions are reusable and maintainable
- [ ] Error messages are helpful for debugging

### Git
- [ ] Changes committed with proper message
- [ ] Commit references Issue #31 and Epic #15
- [ ] Ready to proceed to Stage 2

---

## Files Modified

- `tests/bash/helpers/test-helpers.bash` (+60 lines)

---

## Expected Output

After completing this stage:
- ✅ Two new helper functions available for use
- ✅ Functions tested and verified to work
- ✅ Code committed to branch
- ✅ Ready to update integration tests in Stage 2

---

**Stage Status**: ⏳ READY TO START
**Next Stage**: Stage 2 - Update Enhanced Features Tests
**Estimated Completion**: 30 minutes
