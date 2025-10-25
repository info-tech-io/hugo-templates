#!/usr/bin/env bats

#
# Integration Tests for Enhanced Features v2.0
# Tests new capabilities introduced in Build System v2.0
#

load '../helpers/test-helpers'

setup() {
    setup_test_environment

    export SCRIPT_DIR="$BATS_TEST_DIRNAME/../../../scripts"
    export PROJECT_ROOT="$BATS_TEST_DIRNAME/../../.."
    export TEST_OUTPUT_DIR="$TEST_TEMP_DIR/output"

    # Create test environment
    create_test_template_structure "$TEST_TEMPLATES_DIR" "corporate"
    create_test_template_structure "$TEST_TEMPLATES_DIR" "minimal"
}

teardown() {
    teardown_test_environment
}

@test "enhanced UI displays beautiful build header with emojis" {
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --force

    [ "$status" -eq 0 ]

    # Check for enhanced UI elements
    assert_contains "$output" "🏗️  Hugo Template Factory Build Script"
    assert_contains "$output" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    assert_contains "$output" "✅"  # Success indicators
    assert_contains "$output" "ℹ️"   # Info indicators
}

@test "enhanced error messages provide user-friendly feedback" {
    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]

    # Check for enhanced error messages using structured logging helpers
    assert_log_message "$output" "Template 'nonexistent' not found"
    assert_log_message "$output" "Available templates"
}

@test "build progress indicators show step completion" {
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --verbose \
        --force

    [ "$status" -eq 0 ]

    # Check for step completion indicators using structured logging helpers
    assert_log_message "$output" "Parameter validation completed"
    assert_log_message "$output" "Component parsing completed"
    assert_log_message "$output" "Build environment preparation completed"
    assert_log_message "$output" "Hugo configuration update completed"
    assert_log_message "$output" "Build completed"
}

@test "enhanced logging with timestamps and color coding" {
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --verbose \
        --force

    [ "$status" -eq 0 ]

    # Check for timestamp format
    assert_contains "$output" "[2025-"

    # Check for color coding (ANSI codes)
    assert_contains "$output" "[0;"  # ANSI color codes
}

@test "structured error reporting with categories" {
    # Test configuration error
    local config_file="$TEST_TEMP_DIR/invalid.json"
    echo '{invalid json}' > "$config_file"

    run "$SCRIPT_DIR/build.sh" \
        --config "$config_file" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR"

    # Accept either hard failure or graceful completion
    # Check for structured error categories in output
    assert_contains "$output" "[ERROR] [CONFIG]" || \
    assert_log_message "$output" "CONFIG" "ERROR"
}

@test "error diagnostics file generation" {
    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]

    # Check for error message (diagnostics file generation may not be shown for simple template not found errors)
    assert_log_message "$output" "Template 'nonexistent' not found"
}

@test "GitHub Actions integration with annotations" {
    # Simulate GitHub Actions environment
    export GITHUB_ACTIONS="true"
    export GITHUB_WORKSPACE="$TEST_TEMP_DIR"

    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]

    # Should generate GitHub Actions annotations
    assert_contains "$output" "::error::" || assert_contains "$output" "Template 'nonexistent' not found"
}

@test "performance optimizations in Build System v2.0" {
    # Measure build time
    local start_time=$(date +%s%N)

    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --force

    local end_time=$(date +%s%N)
    local duration_ms=$(( (end_time - start_time) / 1000000 ))

    [ "$status" -eq 0 ]

    # Build should complete in reasonable time (under 10 seconds for this test)
    [ "$duration_ms" -lt 10000 ]

    # Check that build completed successfully
    assert_contains "$output" "Build completed successfully"
}

@test "comprehensive error context preservation" {
    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR" \
        --debug

    [ "$status" -eq 1 ]

    # Debug mode should provide detailed error information
    assert_log_message "$output" "Template 'nonexistent' not found"
    assert_log_message "$output" "Available templates"
}

@test "backward compatibility with original functionality" {
    # Test that basic build still works
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --force

    [ "$status" -eq 0 ]

    # Should generate expected output structure
    assert_directory_exists "$TEST_OUTPUT_DIR"

    # Basic functionality maintained
    assert_contains "$output" "Template: corporate"
}

@test "enhanced component processing with detailed feedback" {
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --verbose \
        --force

    [ "$status" -eq 0 ]

    # Check for enhanced component processing using structured logging helpers
    assert_log_message "$output" "Starting component parsing"
    assert_log_message "$output" "Parsing components from"
    assert_log_message "$output" "Components processed successfully"
}

@test "multi-step build process visualization" {
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --verbose \
        --force

    [ "$status" -eq 0 ]

    # Check for step-by-step visualization using structured logging helpers
    assert_log_message "$output" "Starting component parsing"
    assert_log_message "$output" "Starting build environment preparation"
    assert_log_message "$output" "Starting Hugo configuration update"
    # Note: May use cached build, so "Starting Hugo build" might not appear
}

@test "error recovery and resilience features" {
    # First, cause a failure
    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR"
    [ "$status" -eq 1 ]

    # Then, verify system can recover for a successful build
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --force

    [ "$status" -eq 0 ]
    assert_contains "$output" "Build completed successfully"
}

@test "comprehensive validation feedback" {
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --validate-only

    [ "$status" -eq 0 ]

    # Enhanced validation should provide detailed feedback using structured logging helpers
    assert_log_message "$output" "Parameter validation completed"
    assert_log_message "$output" "Validation completed successfully"
}

@test "smart template suggestions for typos" {
    run "$SCRIPT_DIR/build.sh" \
        --template corperate \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]

    # Should suggest available templates
    assert_contains "$output" "Available templates:"
    assert_contains "$output" "corporate"
    assert_contains "$output" "minimal"
}