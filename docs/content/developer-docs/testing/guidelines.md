---
title: "Testing Guidelines"
description: "Comprehensive testing standards and best practices for Hugo Templates Framework"
weight: 20
---

# Testing Guidelines

Comprehensive testing standards and best practices based on real experience from fixing and improving our test suite.

## Table of Contents

1. [Testing Philosophy](#testing-philosophy)
2. [BATS Test Anatomy](#bats-test-anatomy)
3. [Common Patterns](#common-patterns)
4. [Mock Functions](#mock-functions)
5. [Test Isolation](#test-isolation)
6. [Real-World Examples](#real-world-examples)
7. [Troubleshooting](#troubleshooting)

---

## Testing Philosophy

### Why We Test

**Tests are not checkboxes** - They're validation tools that ensure code works correctly.

❌ **Wrong Mindset**: "I need to write a test so I can check this box"
✅ **Right Mindset**: "I need to verify this function behaves correctly in all scenarios"

### Principles of Good Testing

#### 1. Tests Must Validate Real Functionality

Tests should actually verify that code works, not just execute it.

❌ **BAD - Test Always Passes**:
```bash
@test "function works" {
    run my_function
    [ "$status" -eq 0 ]  # Always passes even if function does nothing
}
```

✅ **GOOD - Test Validates Behavior**:
```bash
@test "function creates expected output file" {
    run my_function

    [ "$status" -eq 0 ]
    [ -f "$EXPECTED_OUTPUT_FILE" ]  # Actually checks side effect
    assert_contains "$(cat $EXPECTED_OUTPUT_FILE)" "expected content"
}
```

#### 2. Tests Should Fail When They Should

A test that never fails is not testing anything useful.

✅ **Good Test Characteristics**:
- Fails when the code is broken
- Passes when the code works correctly
- Can be intentionally broken to verify it detects failures

**Example**: After writing a test, temporarily break the function it tests to verify the test fails.

#### 3. Clear, Descriptive Names

Test names should describe what's being tested and expected behavior.

❌ **BAD**:
```bash
@test "test1" { ... }
@test "check validation" { ... }
```

✅ **GOOD**:
```bash
@test "validate_parameters accepts valid template" { ... }
@test "validate_parameters rejects template with invalid name format" { ... }
```

#### 4. Test Isolation

Each test should be independent and not rely on others.

✅ **Isolation Requirements**:
- Can run in any order
- Has its own setup/teardown
- Doesn't pollute global state
- Uses temporary directories

#### 5. Test Both Success and Failure

Always test both happy paths and error scenarios.

✅ **Complete Test Coverage**:
```bash
# Happy path
@test "load_module_config processes valid JSON" { ... }

# Error cases
@test "load_module_config handles missing file" { ... }
@test "load_module_config handles malformed JSON" { ... }
@test "load_module_config handles empty file" { ... }
```

---

## BATS Test Anatomy

### Basic Structure

```bash
@test "test description" {
    # 1. Setup (optional)
    setup_test_data

    # 2. Execute
    run function_under_test

    # 3. Assert
    [ "$status" -eq 0 ]
    assert_contains "$output" "expected result"

    # 4. Cleanup (optional, usually in teardown)
    cleanup_test_data
}
```

### Setup and Teardown

```bash
setup() {
    # Runs before each test
    setup_test_environment
    export TEST_VAR="value"
}

teardown() {
    # Runs after each test
    teardown_test_environment
    unset TEST_VAR
}
```

### Assertions

**Built-in BATS Assertions**:
```bash
[ "$status" -eq 0 ]          # Check exit code
[ "$output" = "expected" ]   # Exact match
[[ "$output" =~ pattern ]]   # Regex match
[ -f "$file" ]               # File exists
[ -d "$dir" ]                # Directory exists
```

**Custom Helper Assertions** (`tests/bash/helpers/test-helpers.bash`):
```bash
assert_contains "$output" "substring"     # Output contains string
assert_performance_threshold "$ms" 500    # Performance check
```

---

## Common Patterns

### Pattern A: Variable Scope (run vs Direct Call)

This is one of the most important patterns to understand for BATS testing.

#### The Problem

`run` executes commands in a subshell. Variables set in subshells don't propagate to parent shell.

❌ **WRONG - Using `run` When Checking Variables**:
```bash
@test "function sets ERROR_FUNCTION variable" {
    run enter_function "test_function"

    # FAILS! ERROR_FUNCTION is set in subshell, not visible here
    [ "$ERROR_FUNCTION" = "test_function" ]
}
```

**Why it fails**: `run` creates a subshell. `ERROR_FUNCTION` is set there but doesn't propagate back.

✅ **CORRECT - Direct Call for Variable Checks**:
```bash
@test "function entry/exit tracking" {
    # Call directly (no 'run') to check variable in same shell
    enter_function "test_function"

    # WORKS! Variable set in same shell
    [ "$ERROR_FUNCTION" = "test_function" ]

    # Test function exit
    exit_function
    [ -z "$ERROR_FUNCTION" ] || [ "$ERROR_FUNCTION" != "test_function" ]
}
```

**Real Example from Our Codebase**: Test #24 (function entry/exit tracking)
- **Location**: `tests/bash/unit/error-handling.bats:83`
- **Fixed By**: Removing `run` wrapper to preserve variable state

#### When to Use `run` vs Direct Call

✅ **Use `run` when**:
- Checking exit codes
- Capturing output
- Testing command execution
- No need to check variables

✅ **Use Direct Call when**:
- Checking or setting variables
- Variables need to persist
- Testing state changes

**Decision Tree**:
```
Need to check variables?
├─ Yes → Use direct call
└─ No → Use run
```

---

### Pattern B: Error Code Capture with `set -e`

`set -e` causes scripts to exit on any error, which interferes with capturing error codes in tests.

#### The Problem

```bash
@test "function handles error" {
    # Script has 'set -e', so this causes immediate exit
    run failing_function
    [ "$status" -eq 1 ]  # Never reached!
}
```

#### Solution: `run_safely` Wrapper

We created a `run_safely` helper function that properly captures error codes even with `set -e`.

❌ **WRONG - Direct `run` with Error Expected**:
```bash
@test "validate_parameters handles missing Hugo" {
    mv "$TEST_TEMP_DIR/bin/hugo" "$TEST_TEMP_DIR/bin/hugo.bak"

    run validate_parameters  # May exit due to 'set -e'
    [ "$status" -eq 1 ]

    mv "$TEST_TEMP_DIR/bin/hugo.bak" "$TEST_TEMP_DIR/bin/hugo"
}
```

✅ **CORRECT - Using `run_safely`**:
```bash
@test "validate_parameters handles missing Hugo" {
    mv "$TEST_TEMP_DIR/bin/hugo" "$TEST_TEMP_DIR/bin/hugo.bak"

    run_safely validate_parameters  # Properly captures error code
    [ "$status" -eq 1 ]
    assert_contains "$output" "Hugo is not installed"

    mv "$TEST_TEMP_DIR/bin/hugo.bak" "$TEST_TEMP_DIR/bin/hugo"
}
```

**Real Examples from Our Codebase**:
- Test #4: validate_parameters handles missing Hugo
- Test #18: functions handle file permission errors
- Test #26: safe file operations validation
- Test #27: safe command execution
- Test #33: backward compatibility with legacy functions

**Implementation** (from `tests/bash/helpers/test-helpers.bash`):
```bash
run_safely() {
    # Disable error trap temporarily
    local old_trap=$(trap -p ERR)
    trap - ERR

    # Run command and capture result
    local result=0
    "$@" || result=$?

    # Restore error trap
    eval "$old_trap"

    return $result
}
```

---

### Pattern C: Mock Functions

Mock functions simulate dependencies for isolated testing.

#### Creating Effective Mocks

❌ **BAD - Mock Does Nothing**:
```bash
hugo() {
    return 0  # Too simple, doesn't simulate real behavior
}
```

✅ **GOOD - Mock Simulates Real Behavior**:
```bash
hugo() {
    # Simulate real Hugo behavior
    if [[ "$1" == "version" ]]; then
        echo "Hugo Static Site Generator v0.148.0"
        return 0
    fi

    if [[ -d "$2" ]]; then
        # Simulate successful build
        mkdir -p "$2/public"
        echo "Site built successfully"
        return 0
    fi

    echo "Error: invalid directory"
    return 1
}
```

#### Mock Limitations

Be aware of what your mocks don't do:

**Real Example from Our Codebase** (Test #8):
```bash
@test "load_module_config handles missing Node.js" {
    CONFIG="$TEST_TEMP_DIR/module.json"
    create_test_module_config "$CONFIG"

    mv "$TEST_TEMP_DIR/bin/node" "$TEST_TEMP_DIR/bin/node.bak"

    run load_module_config "$CONFIG"
    # Note: Mock function uses jq, not Node.js, so this test passes
    # In real implementation, this would check for Node.js
    [ "$status" -eq 0 ]

    mv "$TEST_TEMP_DIR/bin/node.bak" "$TEST_TEMP_DIR/bin/node"
}
```

**Lesson**: Document when mock behavior differs from reality.

---

### Pattern D: Parameter Passing

Always pass required parameters to functions in tests.

❌ **WRONG - Missing Required Parameter**:
```bash
@test "load_module_config handles missing config file" {
    CONFIG=""

    run load_module_config  # Missing parameter!
    [ "$status" -eq 1 ]
}
```

**Why it fails**: Function receives no argument, not an empty string. Behavior is undefined.

✅ **CORRECT - Pass Parameter Explicitly**:
```bash
@test "load_module_config handles missing config file" {
    CONFIG=""

    run load_module_config "$CONFIG"  # Explicitly pass empty string
    [ "$status" -eq 1 ]
    assert_contains "$output" "Configuration file not found"
}
```

**Real Examples from Our Codebase**:
- Tests #5-#12: All configuration and component tests
- **Fixed in Stage 3**: Added missing parameters to 7 tests

---

### Pattern E: Test Isolation with Temporary Directories

Prevent tests from interfering with each other using isolated temp directories.

❌ **WRONG - Shared Directory Causes Pollution**:
```bash
@test "parse_components handles missing components.yml" {
    TEMPLATE="minimal"

    # Uses shared PROJECT_ROOT - might conflict with other tests
    run parse_components "$PROJECT_ROOT/templates/$TEMPLATE"
    [ "$status" -eq 0 ]
}
```

✅ **CORRECT - Isolated Temporary Directory**:
```bash
@test "parse_components handles missing components.yml" {
    TEMPLATE="minimal"

    # Create isolated directory for this test
    local template_dir="$TEST_TEMP_DIR/templates/minimal-isolated"
    mkdir -p "$template_dir"

    run parse_components "$template_dir"
    [ "$status" -eq 0 ]
    assert_contains "$output" "No components.yml found"
}
```

**Real Example from Our Codebase**: Test #9
- **Location**: `tests/bash/unit/build-functions.bats:190`
- **Fixed in Stage 3**: Used isolated TEST_TEMP_DIR to prevent contamination

---

### Pattern F: Testing Verbose Output

When testing verbose mode, check for additional information without being too specific.

❌ **WRONG - Too Specific**:
```bash
@test "verbose mode provides additional output" {
    VERBOSE="true"

    run validate_parameters
    [ "$status" -eq 0 ]

    # TOO SPECIFIC - breaks if exact wording changes
    assert_contains "$output" "Template path: /exact/path/here"
}
```

✅ **CORRECT - Flexible Checks**:
```bash
@test "verbose mode provides additional output" {
    VERBOSE="true"
    TEMPLATE="corporate"
    mkdir -p "$PROJECT_ROOT/templates/corporate"

    run validate_parameters
    [ "$status" -eq 0 ]

    # Check for verbose indicators, not exact strings
    assert_contains "$output" "Template path" || assert_contains "$output" "Found"
}
```

**Real Example from Our Codebase**: Test #15
- **Fixed in Stage 3**: Enhanced mock to output verbose information

---

## Mock Functions

### Mock Function Guidelines

#### 1. Mock Only What's Necessary

Mock external dependencies, not internal functions.

✅ **Mock These**:
- External commands (hugo, node, jq)
- File system operations (when testing error handling)
- Network calls
- System utilities

❌ **Don't Mock These**:
- Functions you're testing
- Simple utilities that work fine
- Standard Bash built-ins

#### 2. Maintain Consistent Behavior

Mocks should behave similarly to real commands.

```bash
# Good mock - similar interface to real command
jq() {
    # Accept same arguments as real jq
    if [[ "$1" == "." ]] && [[ -f "$2" ]]; then
        cat "$2"
        return 0
    fi
    return 1
}
```

#### 3. Document Mock Limitations

```bash
@test "load_module_config handles missing Node.js" {
    # ... test code ...

    # Note: Mock function uses jq, not Node.js
    # In real implementation, this would check for Node.js
    [ "$status" -eq 0 ]
}
```

#### 4. Common Mock Patterns

**Hugo Mock**:
```bash
hugo() {
    case "$1" in
        version)
            echo "Hugo Static Site Generator v0.148.0"
            ;;
        *)
            if [[ -d "${@: -1}" ]]; then
                echo "Building sites..."
                mkdir -p "${@: -1}/public"
                echo "Site built"
            fi
            ;;
    esac
}
```

**Node.js Mock**:
```bash
node() {
    # Simple mock for configuration parsing
    if [[ -f "$1" ]] && [[ -f "$2" ]]; then
        echo "TEMPLATE=corporate"
        echo "THEME=compose"
    else
        echo "Error: file not found"
        return 1
    fi
}
```

---

## Test Isolation

### Principles of Test Isolation

1. **Each test is independent** - Can run in any order
2. **No shared state** - Tests don't affect each other
3. **Clean environment** - Start fresh, clean up after
4. **Temporary resources** - Use TEST_TEMP_DIR

### Setup and Teardown

**setup() function**:
```bash
setup() {
    # 1. Create test environment
    setup_test_environment  # Creates TEST_TEMP_DIR

    # 2. Set required variables
    export PROJECT_ROOT="$BATS_TEST_DIRNAME/../../.."
    export TEMPLATE="corporate"

    # 3. Create mock functions
    create_build_functions_for_testing
}
```

**teardown() function**:
```bash
teardown() {
    # Cleanup automatically handled by test-helpers
    teardown_test_environment  # Removes TEST_TEMP_DIR

    # Additional cleanup if needed
    unset CUSTOM_VARIABLE
}
```

### Using TEST_TEMP_DIR

**TEST_TEMP_DIR** is a temporary directory unique to each test run.

✅ **Always use for**:
- Creating test files
- Temporary output
- Mock directory structures

```bash
@test "creates configuration file" {
    local config_file="$TEST_TEMP_DIR/config.json"

    run create_config "$config_file"

    [ "$status" -eq 0 ]
    [ -f "$config_file" ]
}
```

### Preventing Cross-Test Contamination

❌ **BAD - Modifying Shared Resources**:
```bash
@test "test modifies shared directory" {
    echo "test data" > "$PROJECT_ROOT/templates/corporate/test.txt"
    # This affects other tests!
}
```

✅ **GOOD - Using Isolated Resources**:
```bash
@test "test uses isolated directory" {
    local isolated_dir="$TEST_TEMP_DIR/templates/corporate"
    mkdir -p "$isolated_dir"
    echo "test data" > "$isolated_dir/test.txt"
    # Automatically cleaned up, doesn't affect other tests
}
```

---

## Real-World Examples

These examples come from actual issues we encountered and fixed in Stage 3 of Issue #26.

### Example 1: Variable Scope Issue (Tests #24, #25)

**Problem**: Tests were failing because `run` created a subshell.

**Before (Failed)**:
```bash
@test "function entry/exit tracking" {
    run enter_function "test_function"
    [ "$ERROR_FUNCTION" = "test_function" ]  # FAILED - variable not set
}
```

**After (Fixed)**:
```bash
@test "function entry/exit tracking" {
    # Removed 'run' wrapper to check variable in same shell
    enter_function "test_function"
    [ "$ERROR_FUNCTION" = "test_function" ]  # WORKS!

    exit_function
    [ -z "$ERROR_FUNCTION" ] || [ "$ERROR_FUNCTION" != "test_function" ]
}
```

**Lesson**: Don't use `run` when you need to check variables.

---

### Example 2: Missing Parameters (Tests #5-#10)

**Problem**: Tests called functions without required parameters.

**Before (Failed)**:
```bash
@test "load_module_config handles missing config file" {
    CONFIG=""
    run load_module_config  # Missing parameter!
    [ "$status" -eq 1 ]     # Test failed
}
```

**After (Fixed)**:
```bash
@test "load_module_config handles missing config file" {
    CONFIG=""
    run load_module_config "$CONFIG"  # Explicitly pass parameter
    [ "$status" -eq 1 ]
    assert_contains "$output" "Configuration file not found"
}
```

**Lesson**: Always pass required parameters explicitly, even if empty.

---

### Example 3: Wrong Test Expectations (Test #15)

**Problem**: Test expected verbose output that mock function didn't produce.

**Before (Failed)**:
```bash
@test "verbose mode provides additional output" {
    VERBOSE="true"
    run validate_parameters
    [ "$status" -eq 0 ]
    assert_contains "$output" "Template path"  # FAILED - mock didn't output this
}
```

**After (Fixed)**:
```bash
# Enhanced mock to check VERBOSE flag
validate_parameters() {
    log_info "Validating parameters..."

    # ... validation logic ...

    # Verbose output (ADDED)
    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Template path: $PROJECT_ROOT/templates/$TEMPLATE"
        log_info "Found template: $TEMPLATE"
    fi

    log_info "Parameter validation completed"
    return 0
}
```

**Lesson**: Ensure mocks produce expected output for all modes.

---

### Example 4: Error Handling with run_safely (Test #18, #26, #27, #33)

**Problem**: `set -e` caused tests to exit before capturing error codes.

**Before (Problematic)**:
```bash
@test "functions handle file permission errors" {
    simulate_permission_error "$CONFIG"
    run load_module_config "$CONFIG"  # Might exit due to 'set -e'
    [ "$status" -eq 1 ]
}
```

**After (Fixed)**:
```bash
@test "functions handle file permission errors" {
    simulate_permission_error "$CONFIG"
    run_safely load_module_config "$CONFIG"  # Properly captures error
    [ "$status" -eq 1 ]

    chmod 644 "$CONFIG" 2>/dev/null || true  # Cleanup
}
```

**Lesson**: Use `run_safely` when testing error scenarios with `set -e`.

---

### Example 5: Test Isolation (Test #9)

**Problem**: Test contaminated shared directory, affecting other tests.

**Before (Problematic)**:
```bash
@test "parse_components handles missing components.yml" {
    TEMPLATE="minimal"

    # Uses shared directory - potential conflicts
    run parse_components "$PROJECT_ROOT/templates/$TEMPLATE"
    [ "$status" -eq 0 ]
}
```

**After (Fixed)**:
```bash
@test "parse_components handles missing components.yml" {
    TEMPLATE="minimal"

    # Create isolated directory
    local template_dir="$TEST_TEMP_DIR/templates/minimal-no-components"
    mkdir -p "$template_dir"

    run parse_components "$template_dir"
    [ "$status" -eq 0 ]
    assert_contains "$output" "No components.yml found"
}
```

**Lesson**: Use isolated temporary directories to prevent test pollution.

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: "Variable not set" Errors

**Symptom**: Test fails with "unbound variable" error.

**Cause**: Using variable before it's set, especially with `set -u`.

**Solution**:
```bash
# Check if variable is set before using
if [[ -n "${MY_VAR:-}" ]]; then
    echo "$MY_VAR"
fi

# Or set default
echo "${MY_VAR:-default_value}"
```

---

#### Issue 2: "Command not found" in Tests

**Symptom**: Test fails with "command not found" for standard commands.

**Cause**: Test environment doesn't have same PATH as normal shell.

**Solution**:
```bash
setup() {
    setup_test_environment

    # Add mock bin directory to PATH
    export PATH="$TEST_TEMP_DIR/bin:$PATH"

    # Create mock commands
    create_mock_commands
}
```

---

#### Issue 3: Flaky Tests (Pass Sometimes, Fail Sometimes)

**Symptom**: Test passes on some runs, fails on others.

**Common Causes**:
1. **Race conditions** - Timing-dependent code
2. **Shared state** - Tests affecting each other
3. **External dependencies** - Network, filesystem
4. **Random data** - Using non-deterministic test data

**Solutions**:
```bash
# 1. Add explicit waits
sleep 0.1  # Give async operations time to complete

# 2. Ensure test isolation
local isolated_dir="$TEST_TEMP_DIR/unique-name-$$"

# 3. Mock external dependencies
create_mock_network_response

# 4. Use deterministic test data
RANDOM_SEED=42
```

---

#### Issue 4: Test Passes But Shouldn't

**Symptom**: Test passes even when function is broken.

**Cause**: Test doesn't actually validate functionality.

**Solution**: Intentionally break the function to verify test fails.

```bash
# Original test
@test "function creates file" {
    run my_function
    [ "$status" -eq 0 ]  # Not enough!
}

# Improved test
@test "function creates file with correct content" {
    run my_function

    [ "$status" -eq 0 ]
    [ -f "$EXPECTED_FILE" ]  # Check file exists
    assert_contains "$(cat $EXPECTED_FILE)" "expected content"  # Check content
}
```

---

#### Issue 5: Output Not Captured

**Symptom**: `$output` variable is empty even though command produces output.

**Cause**: Not using `run` to capture output.

**Solution**:
```bash
# Wrong
my_function
assert_contains "$output" "text"  # $output is empty!

# Correct
run my_function
assert_contains "$output" "text"  # $output contains command output
```

---

### Debugging Tests

#### Enable Verbose Output

```bash
# Run tests with verbose flag
./scripts/test-bash.sh --suite unit --verbose

# Or run BATS directly
bats -t tests/bash/unit/build-functions.bats
```

#### Add Debug Output to Tests

```bash
@test "debug test" {
    echo "DEBUG: Variable value: $MY_VAR" >&3  # >&3 shows in verbose mode

    run my_function

    echo "DEBUG: Status: $status" >&3
    echo "DEBUG: Output: $output" >&3

    [ "$status" -eq 0 ]
}
```

#### Run Single Test

```bash
# Run specific test by name
bats -f "validate_parameters accepts valid template" tests/bash/unit/build-functions.bats
```

#### Check Test Environment

```bash
@test "check environment" {
    echo "PWD: $PWD" >&3
    echo "PATH: $PATH" >&3
    echo "TEST_TEMP_DIR: $TEST_TEMP_DIR" >&3
    ls -la "$TEST_TEMP_DIR" >&3
}
```

---

## Best Practices Checklist

Use this checklist when writing or reviewing tests:

### Test Quality
- [ ] Test has clear, descriptive name
- [ ] Test validates real functionality, not just execution
- [ ] Test can fail (verify by intentionally breaking code)
- [ ] Test has both positive and negative cases
- [ ] Test is isolated and independent

### Code Quality
- [ ] Uses `run` for capturing output and exit codes
- [ ] Uses direct call when checking variables
- [ ] Uses `run_safely` for error scenarios with `set -e`
- [ ] Passes all required parameters explicitly
- [ ] Uses TEST_TEMP_DIR for temporary files

### Documentation
- [ ] Test purpose is clear from name
- [ ] Complex logic has comments
- [ ] Mock limitations are documented
- [ ] Related tests are grouped

### Maintenance
- [ ] Test is added to test-inventory.md
- [ ] Test follows established patterns
- [ ] Test doesn't duplicate existing coverage
- [ ] Test will be maintainable long-term

---

## Related Documentation

- [Test Inventory](../test-inventory/) - Complete catalog of all tests
- [Coverage Matrix](../coverage-matrix/) - Function coverage analysis
- [Contributing Guide](../../contributing/) - General contribution guidelines

---

**Remember**: Good tests are clear, isolated, and actually validate functionality. When in doubt, refer to the real-world examples in this guide!

**Last Updated**: 2025-10-11
