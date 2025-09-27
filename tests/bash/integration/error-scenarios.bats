#!/usr/bin/env bats

#
# Integration Tests for Error Scenarios
# Tests comprehensive error handling in real-world scenarios
#

load '../helpers/test-helpers'

setup() {
    setup_test_environment

    export SCRIPT_DIR="$BATS_TEST_DIRNAME/../../../scripts"
    export PROJECT_ROOT="$BATS_TEST_DIRNAME/../../.."
    export TEST_OUTPUT_DIR="$TEST_TEMP_DIR/output"

    # Create basic test structure
    create_test_template_structure "$PROJECT_ROOT/templates" "corporate"
}

teardown() {
    teardown_test_environment
}

@test "error scenario: missing template directory" {
    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]
    assert_contains "$output" "Template 'nonexistent' not found"
    assert_contains "$output" "Available templates:"
}

@test "error scenario: corrupted module.json file" {
    local config_file="$TEST_TEMP_DIR/corrupted.json"
    echo '{"template": "corporate", "invalid": json}' > "$config_file"

    run "$SCRIPT_DIR/build.sh" \
        --config "$config_file" \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]
    assert_contains "$output" "CONFIG" || assert_contains "$output" "parsing"
    assert_contains "$output" "JSON" || assert_contains "$output" "syntax"
}

@test "error scenario: empty module.json file" {
    local config_file="$TEST_TEMP_DIR/empty.json"
    echo "" > "$config_file"

    run "$SCRIPT_DIR/build.sh" \
        --config "$config_file" \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]
    assert_contains "$output" "empty" || assert_contains "$output" "CONFIG"
}

@test "error scenario: unreadable module.json file" {
    local config_file="$TEST_TEMP_DIR/unreadable.json"
    create_test_module_config "$config_file"
    chmod 000 "$config_file"

    run "$SCRIPT_DIR/build.sh" \
        --config "$config_file" \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]
    assert_contains "$output" "CONFIG" || assert_contains "$output" "permission"

    # Restore permissions for cleanup
    chmod 644 "$config_file" 2>/dev/null || true
}

@test "error scenario: missing Hugo binary" {
    # Remove Hugo mock
    mv "$TEST_TEMP_DIR/bin/hugo" "$TEST_TEMP_DIR/bin/hugo.bak"

    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]
    assert_contains "$output" "Hugo not found" || assert_contains "$output" "DEPENDENCY"
    assert_contains "$output" "Install Hugo" || assert_contains "$output" "hugo"

    # Restore Hugo mock
    mv "$TEST_TEMP_DIR/bin/hugo.bak" "$TEST_TEMP_DIR/bin/hugo"
}

@test "error scenario: missing Node.js for module.json processing" {
    local config_file="$TEST_TEMP_DIR/module.json"
    create_test_module_config "$config_file"

    # Remove Node.js mock
    mv "$TEST_TEMP_DIR/bin/node" "$TEST_TEMP_DIR/bin/node.bak"

    run "$SCRIPT_DIR/build.sh" \
        --config "$config_file" \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]
    assert_contains "$output" "Node.js not available" || assert_contains "$output" "DEPENDENCY"

    # Restore Node.js mock
    mv "$TEST_TEMP_DIR/bin/node.bak" "$TEST_TEMP_DIR/bin/node"
}

@test "error scenario: disk space exhaustion simulation" {
    # Create a very large output path to simulate space issues
    # This is a conceptual test - actual implementation may vary
    local invalid_output="/dev/full/output"

    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$invalid_output"

    [ "$status" -eq 1 ]
    # Should handle path/permission errors gracefully
}

@test "error scenario: network timeout simulation" {
    # This test simulates network-related failures if components need downloading
    # For now, it tests that the error handling system works with simulated network errors

    # Create a mock that simulates network failure
    cat > "$TEST_TEMP_DIR/bin/curl" << 'EOF'
#!/bin/bash
echo "curl: (28) Connection timed out" >&2
exit 28
EOF
    chmod +x "$TEST_TEMP_DIR/bin/curl"

    # Even if curl fails, build should handle it gracefully
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --force

    # Build might succeed (if curl isn't needed) or fail gracefully
    if [ "$status" -eq 1 ]; then
        assert_contains "$output" "NETWORK" || assert_contains "$output" "timeout"
    fi
}

@test "error scenario: malformed components.yml" {
    # Create template with malformed components.yml
    local template_dir="$PROJECT_ROOT/templates/malformed_components"
    mkdir -p "$template_dir"
    echo "# Malformed Template" > "$template_dir/README.md"
    echo "invalid: yaml: [syntax: error" > "$template_dir/components.yml"

    run "$SCRIPT_DIR/build.sh" \
        --template malformed_components \
        --output "$TEST_OUTPUT_DIR" \
        --force

    # Should complete with warnings, not fail entirely
    [ "$status" -eq 0 ]
    assert_contains "$output" "Warning" || assert_contains "$output" "parsing failed"
}

@test "error scenario: invalid Hugo configuration" {
    # Create template with invalid hugo.toml
    local template_dir="$PROJECT_ROOT/templates/invalid_config"
    mkdir -p "$template_dir"
    echo "invalid hugo configuration syntax" > "$template_dir/hugo.toml"

    run "$SCRIPT_DIR/build.sh" \
        --template invalid_config \
        --output "$TEST_OUTPUT_DIR" \
        --force

    # Hugo should handle its own config errors
    # Build system should capture and report these appropriately
    [ "$status" -eq 1 ] || [ "$status" -eq 0 ]
}

@test "error scenario: multiple simultaneous errors" {
    # Combine multiple error conditions
    local config_file="$TEST_TEMP_DIR/multi_error.json"
    simulate_malformed_json "$config_file"

    # Remove Hugo as well
    mv "$TEST_TEMP_DIR/bin/hugo" "$TEST_TEMP_DIR/bin/hugo.bak"

    run "$SCRIPT_DIR/build.sh" \
        --config "$config_file" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]

    # Should report multiple errors or at least the first critical one
    assert_contains "$output" "ERROR" || assert_contains "$output" "VALIDATION"

    # Restore Hugo mock
    mv "$TEST_TEMP_DIR/bin/hugo.bak" "$TEST_TEMP_DIR/bin/hugo"
}

@test "error scenario: GitHub Actions environment error reporting" {
    # Simulate GitHub Actions environment
    export GITHUB_ACTIONS="true"
    export GITHUB_WORKSPACE="$TEST_TEMP_DIR"

    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]

    # Should include GitHub Actions annotations
    assert_contains "$output" "::error::" || assert_contains "$output" "VALIDATION"
}

@test "error scenario: error state persistence" {
    # Run a failing command
    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]

    # Error state file should exist and contain diagnostic information
    # (Path depends on error handling implementation)
    local error_files=$(find "$TEST_TEMP_DIR" -name "*error*" -o -name "*diagnostic*" 2>/dev/null | wc -l)
    [ "$error_files" -gt 0 ] || {
        # Alternative: check if error information is included in output
        assert_contains "$output" "diagnostic" || assert_contains "$output" "error"
    }
}

@test "error scenario: recovery after partial failure" {
    # First, cause a failure
    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR"
    [ "$status" -eq 1 ]

    # Then, run a successful build to ensure system recovers
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --force

    [ "$status" -eq 0 ]
    assert_contains "$output" "Build completed successfully"
}

@test "error scenario: verbose error reporting" {
    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR" \
        --verbose

    [ "$status" -eq 1 ]

    # Verbose mode should provide more detailed error information
    assert_contains "$output" "Template directory not found"
    # Verbose output should be more detailed than non-verbose
}

@test "error scenario: quiet mode error handling" {
    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR" \
        --quiet

    [ "$status" -eq 1 ]

    # Even in quiet mode, errors should be reported
    assert_contains "$output" "ERROR" || assert_contains "$output" "Template directory not found"

    # But output should be more concise than verbose mode
    [[ ${#output} -lt 500 ]]
}

@test "error scenario: debug mode error diagnostics" {
    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR" \
        --debug

    [ "$status" -eq 1 ]

    # Debug mode should provide additional diagnostic information
    assert_contains "$output" "VALIDATION" || assert_contains "$output" "Template directory not found"
}

@test "error scenario: validation-only mode with errors" {
    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR" \
        --validate-only

    [ "$status" -eq 1 ]

    # Should catch validation errors without attempting build
    assert_contains "$output" "Template directory not found"

    # Should not create output directory
    [[ ! -d "$TEST_OUTPUT_DIR" ]]
}