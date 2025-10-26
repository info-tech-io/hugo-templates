---
title: "Testing Guidelines"
description: "Comprehensive testing standards and best practices for Hugo Templates Framework"
weight: 20
---

# Testing Guidelines

Comprehensive testing standards and best practices based on real experience from fixing and improving our test suite.

## Table of Contents

1.  [Testing Philosophy](#testing-philosophy)
2.  [Key Patterns](#key-patterns)
    -   [Graceful Error Handling](#pattern-a-graceful-error-handling)
    -   [True Test Isolation](#pattern-b-true-test-isolation)
    -   [CI-Specific Considerations](#pattern-c-ci-specific-considerations)
3.  [BATS Test Anatomy](#bats-test-anatomy)
4.  [Assertion Helpers](#assertion-helpers)
5.  [Mock Functions](#mock-functions)
6.  [Troubleshooting](#troubleshooting)

---

## Testing Philosophy

### Why We Test

**Tests are not checkboxes** - They are validation tools that ensure our code works correctly under all conditions. They are the most critical defense against regressions.

❌ **Wrong Mindset**: "I need to write a test so I can check this box."
✅ **Right Mindset**: "I need to verify this function behaves correctly in all scenarios, especially in our CI environment."

### Principles of Good Testing

1.  **Validate Real Functionality**: Tests must verify that code works, not just that it runs without crashing.
2.  **Fail When They Should**: A test that never fails is not a useful test. Intentionally break the code to ensure the test catches the failure.
3.  **Clear, Descriptive Names**: Test names should describe what is being tested and the expected behavior (e.g., `error scenario: missing Hugo binary`).
4.  **Absolute Isolation**: Each test must be independent and run in a clean, temporary environment. **No test should ever modify the project's working directory.**
5.  **Test Both Success and Failure**: Always test the "happy path" and multiple error scenarios.

---

## Key Patterns

Recent bug fixes have introduced critical new patterns that all contributors must follow.

### Pattern A: Graceful Error Handling

Our build script often uses "graceful error handling," meaning it might encounter an error, log it, and still exit with a status code of `0`. Tests that only check for `[ "$status" -eq 1 ]` will fail.

**The Problem**: A test expects a hard failure (`exit 1`), but the script handles the error gracefully and exits `0`.

❌ **WRONG - Brittle Exit Code Check**:
```bash
@test "error scenario: empty module.json file" {
    run "$SCRIPT_DIR/build.sh" --config "empty.json" --template nonexistent

    # This is wrong! The script might exit 0 and log the error.
    [ "$status" -eq 1 ]
    assert_contains "$output" "empty"
}
```

✅ **CORRECT - Flexible Graceful Handling Pattern**:
The correct approach is to check for either a non-zero exit code OR an error message in the structured logs.

```bash
@test "error scenario: empty module.json file" {
    run "$SCRIPT_DIR/build.sh" --config "empty.json" --template nonexistent

    # This pattern correctly handles both hard failures and graceful errors.
    if [ "$status" -ne 0 ]; then
        # If the script failed hard, check the raw output.
        assert_contains "$output" "empty"
    else
        # If the script exited 0, check the structured logs for the error.
        assert_log_message "$output" "empty" "ERROR"
    fi
}
```
This pattern makes the test suite resilient and correctly validates the intended behavior.

### Pattern B: True Test Isolation

Tests **must not** modify the local git repository. All test operations should occur within a temporary directory created by the test harness.

**The Problem**: Tests write files to the project's actual `templates/` or `themes/` directories, resulting in a dirty `git status` after running tests.

❌ **WRONG - Modifying Project Files**:
```bash
@test "creates a new template" {
    # This modifies the actual project and is strictly forbidden.
    local template_dir="$PROJECT_ROOT/templates/my-test-template"
    mkdir -p "$template_dir"
}
```

✅ **CORRECT - Using Isolated Temporary Directories**:
Our test helper `setup_test_environment` creates a safe, isolated environment. Use the provided environment variables to interact with it.

-   `$TEST_TEMP_DIR`: The root of the temporary directory for the test run.
-   `$PROJECT_ROOT`: An isolated project root inside `$TEST_TEMP_DIR`.
-   `$TEST_TEMPLATES_DIR`: An isolated `templates` directory inside the isolated project root.
-   `$ORIGINAL_PROJECT_ROOT`: The real path to the project, to be used only for sourcing scripts.

```bash
setup() {
    # This helper creates the isolated environment for you.
    setup_test_environment
}

@test "creates a new template safely" {
    # Use the isolated directory variable. This is safe.
    local template_dir="$TEST_TEMPLATES_DIR/my-test-template"
    mkdir -p "$template_dir"

    # Assertions can now safely check inside the temp directory.
    assert_directory_exists "$template_dir"
}
```

### Pattern C: CI-Specific Considerations

Tests must be written to pass reliably in our GitHub Actions CI environment.

#### 1. Forcing Failures in Error Scenarios

**The Problem**: The CI environment is set up differently from the local test environment. For example, it pre-creates `templates/corporate`, so a test that expects a "template not found" error might pass incorrectly in CI.

❌ **WRONG - Ambiguous Error Test**:
```bash
@test "handles missing config" {
    # This might pass in CI because the default 'corporate' template exists.
    run "$SCRIPT_DIR/build.sh" --config "missing.json"
}
```

✅ **CORRECT - Explicitly Forcing Failure**:
To ensure an error test fails reliably, explicitly provide parameters that guarantee failure, regardless of the environment.

```bash
@test "handles missing config" {
    # By providing a nonexistent template, we guarantee a validation failure.
    run "$SCRIPT_DIR/build.sh" --config "missing.json" --template nonexistent
}
```

#### 2. Flawed Mocks

**The Problem**: A mock function in `test-helpers.bash` had a critical bug where it would always `exit 0`, even if the real command would have failed. This caused tests to pass locally (using the real command) but fail in CI (which sometimes fell back to the mock).

**The Lesson**: Mocks must accurately reflect the behavior of the real command, especially regarding exit codes. The `node` mock has been fixed to propagate the correct exit code.

---

## BATS Test Anatomy

### Basic Structure
```bash
@test "test description" {
    # 1. Setup (e.g., create test files in $TEST_TEMP_DIR)
    setup_test_data

    # 2. Execute
    run function_under_test

    # 3. Assert (using graceful error handling pattern)
    if [ "$status" -ne 0 ]; then
        assert_contains "$output" "error"
    else
        assert_log_message "$output" "error" "ERROR"
    fi
}
```

### Setup and Teardown
The `setup_test_environment` and `teardown_test_environment` helpers are automatically called in `setup()` and `teardown()` and handle the creation and deletion of the isolated test environment.

---

## Assertion Helpers

Our test suite relies on custom assertion helpers in `tests/bash/helpers/test-helpers.bash`.

### `assert_log_message` (Critical Helper)
This is the most important helper for testing our structured logging output. It makes tests resilient to changes in log format (like timestamps or colors).

**Usage**:
```bash
# assert_log_message "$output" "Message" "LEVEL"

# Checks for an INFO message containing "Build completed"
assert_log_message "$output" "Build completed" "INFO"

# Checks for an ERROR message containing "Template not found"
assert_log_message "$output" "Template not found" "ERROR"
```
It automatically strips ANSI color codes and timestamps before searching, so you only need to check for the core message content and log level.

### `run_safely`
Use this helper when you need to test a command that is expected to fail. It correctly captures non-zero exit codes even when the script uses `set -e`.

---

## Mock Functions

Mocks for external dependencies like `hugo` and `node` are provided in `test-helpers.bash`.

**Key Guideline**: Mocks must be reliable. The `node` mock was fixed to correctly propagate exit codes from the real Node.js executable, which is critical for testing error conditions related to configuration parsing. If you modify a mock, ensure it behaves like the real tool.

---

## Troubleshooting

### Tests Fail in CI but Pass Locally

This is almost always due to one of the CI-specific considerations mentioned above.
1.  **Check for Environment Differences**: Is the CI environment different? Does your test need to be more explicit to force a failure (e.g., `--template nonexistent`)?
2.  **Check for Flawed Mocks**: Is a mock function hiding the error? The `node` mock was a prime example. Ensure mocks propagate exit codes correctly.
3.  **Check for Race Conditions**: While less common in our scripts, ensure tests are not dependent on timing.

### `git status` is Dirty After Running Tests
This indicates a violation of the **Test Isolation** pattern. A test is writing files outside of `$TEST_TEMP_DIR`. Find the offending test and correct it to use the isolated directory variables (`$TEST_TEMPLATES_DIR`, etc.).
