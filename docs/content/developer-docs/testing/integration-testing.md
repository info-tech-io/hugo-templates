---
title: "Integration Testing Guide"
description: "Guide to writing and maintaining end-to-end integration tests"
weight: 25
---

# Integration Testing Guide

This guide provides standards and best practices for writing and maintaining integration tests for the Hugo Templates Framework. Integration tests are a critical part of our quality assurance process, verifying that all components of the build system work together correctly in real-world scenarios.

## 1. Philosophy of Integration Testing

While **unit tests** check individual functions in isolation, **integration tests** validate the entire workflow from end to end.

**Primary Goals**:
-   **Verify Component Interaction**: Ensure that different parts of the build script (e.g., parameter parsing, configuration loading, Hugo execution) work together as expected.
-   **Simulate Real-World Scenarios**: Test the build system under conditions that mimic actual use, including complex configurations and error conditions.
-   **Prevent Regressions**: Catch bugs that only appear when multiple components interact.
-   **Ensure Reliability**: Guarantee that the build script is resilient, provides clear feedback, and handles errors gracefully.

An integration test should be a complete story. It should set up a realistic scenario, execute the main build script, and then validate the final outcome.

## 2. Structure of an Integration Test

Our integration tests are located in `tests/bash/integration/`. Each test file focuses on a specific area of functionality.

**Anatomy of a Typical Integration Test**:
```bash
@test "full build workflow with corporate template succeeds" {
    # 1. Setup: Create a realistic, isolated environment.
    # This uses helpers to create a temporary, isolated template directory.
    create_test_template_structure "$TEST_TEMPLATES_DIR" "corporate"

    # 2. Execute: Run the main build.sh script with realistic parameters.
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --force

    # 3. Assert: Verify the final outcome.
    # Check the exit status.
    [ "$status" -eq 0 ]

    # Check for key success messages in the logs.
    assert_log_message "$output" "Build completed successfully" "SUCCESS"

    # Check for physical artifacts (e.g., the output directory).
    assert_directory_exists "$TEST_OUTPUT_DIR"
}
```

## 3. Key Integration Testing Patterns

### Pattern A: Testing Full Workflows

The most basic integration test is a "happy path" test that runs a complete, successful build. These tests ensure that the primary functionality of the script is always working.

**Example** (`full-build-workflow.bats`):
```bash
@test "full build workflow with module.json configuration" {
    # Setup: Create a valid module.json.
    local config_file="$TEST_TEMP_DIR/module.json"
    create_test_module_config "$config_file" "corporate" "compose"

    # Execute: Run the build using the config file.
    run "$SCRIPT_DIR/build.sh" \
        --config "$config_file" \
        --output "$TEST_OUTPUT_DIR" \
        --force

    # Assert: Verify success.
    [ "$status" -eq 0 ]
    assert_log_message "$output" "Module configuration loaded successfully" "INFO"
    assert_log_message "$output" "Build completed successfully" "SUCCESS"
}
```

### Pattern B: Testing Real-World Error Scenarios

Integration tests are the best place to test how the system responds to errors. These tests should simulate a specific error condition and then verify that the system handles it gracefully.

**Key Principles for Error Tests**:
1.  **Isolate the Failure**: Set up the test to trigger one specific error.
2.  **Force the Error**: Use explicit parameters (like `--template nonexistent`) to ensure the error occurs reliably, especially in CI.
3.  **Use the Graceful Error Handling Pattern**: Check for either a non-zero exit code or an error message in the logs.

**Example** (`error-scenarios.bats`):
```bash
@test "error scenario: corrupted module.json file" {
    # Setup: Create a malformed JSON file.
    local config_file="$TEST_TEMP_DIR/corrupted.json"
    echo '{"invalid": json}' > "$config_file"

    # Execute: Run the build, explicitly forcing a failure condition.
    run "$SCRIPT_DIR/build.sh" \
        --config "$config_file" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR"

    # Assert: Use the graceful error handling pattern.
    if [ "$status" -ne 0 ]; then
        assert_contains "$output" "CONFIG"
    else
        assert_log_message "$output" "CONFIG" "ERROR"
    fi
}
```

### Pattern C: Testing for CI Reliability

As discovered in Issue #35, it is critical to write integration tests that are not dependent on the environment.

**Best Practices**:
-   **Don't Rely on Defaults**: If a test needs a template, create it. If it needs a file to be absent, ensure it is.
-   **Force Failures**: When testing an error, add a parameter like `--template nonexistent` to guarantee that the script's validation will fail, even if the CI environment is configured differently.
-   **Use Robust Mocks**: Ensure any mock functions (like the `node` mock) correctly propagate exit codes to simulate real-world failures.

## 4. Integration Test Suites

Our 52 integration tests are organized into three main files:

-   `full-build-workflow.bats`: Focuses on end-to-end success scenarios and validation of the main build process.
-   `enhanced-features-v2.bats`: Tests the user-facing features like structured logging, UI elements, and smart suggestions.
-   `error-scenarios.bats`: A comprehensive suite of tests that ensures the build system is resilient and handles dozens of potential failure modes correctly.

When adding a new integration test, choose the file that best fits its purpose. If you are adding a test for a new feature, add it to `enhanced-features-v2.bats`. If you are fixing a bug, add a regression test to `error-scenarios.bats`.

## 5. When to Write an Integration Test

Write an integration test instead of a unit test when:

-   You need to verify the interaction between multiple functions or components.
-   You are testing a complete user-facing workflow (e.g., running the build with a specific set of CLI flags).
-   You are testing how the system responds to a real-world error condition (e.g., a missing dependency or a malformed config file).
-   You are fixing a regression that was not caught by existing unit tests.

---
## Related Documentation

- [Testing Guidelines](./guidelines.md) - General testing principles and patterns.
- [Test Inventory](./test-inventory.md) - A complete catalog of all tests.

```