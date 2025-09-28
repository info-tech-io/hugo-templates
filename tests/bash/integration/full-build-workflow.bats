#!/usr/bin/env bats

#
# Integration Tests for Full Build Workflow
# End-to-end testing of complete build process
#

load '../helpers/test-helpers'

setup() {
    setup_test_environment

    # Set up more comprehensive environment for integration tests
    export SCRIPT_DIR="$BATS_TEST_DIRNAME/../../../scripts"
    export PROJECT_ROOT="$BATS_TEST_DIRNAME/../../.."
    export TEST_OUTPUT_DIR="$TEST_TEMP_DIR/output"

    # Create comprehensive test structure
    create_comprehensive_test_environment
}

teardown() {
    teardown_test_environment
}

create_comprehensive_test_environment() {
    # Create templates directory structure
    create_test_template_structure "$PROJECT_ROOT/templates" "corporate"
    create_test_template_structure "$PROJECT_ROOT/templates" "minimal"

    # Create themes directory (mock)
    mkdir -p "$PROJECT_ROOT/themes/compose"
    echo "# Compose Theme" > "$PROJECT_ROOT/themes/compose/README.md"

    # Create components directory (mock)
    mkdir -p "$PROJECT_ROOT/components/quiz-engine"
    echo "# Quiz Engine Component" > "$PROJECT_ROOT/components/quiz-engine/README.md"
}

@test "full build workflow with corporate template succeeds" {
    # Execute full build workflow
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --theme compose \
        --output "$TEST_OUTPUT_DIR" \
        --force \
        --verbose

    [ "$status" -eq 0 ]

    # Verify output structure
    assert_directory_exists "$TEST_OUTPUT_DIR"

    # Check build summary output
    assert_contains "$output" "Build Summary"
    assert_contains "$output" "Template: corporate"
    assert_contains "$output" "Theme: compose"
    assert_contains "$output" "Build completed successfully"
}

@test "full build workflow with minimal template succeeds" {
    run "$SCRIPT_DIR/build.sh" \
        --template minimal \
        --theme compose \
        --output "$TEST_OUTPUT_DIR" \
        --force

    [ "$status" -eq 0 ]
    assert_directory_exists "$TEST_OUTPUT_DIR"
    assert_contains "$output" "Template: minimal"
}

@test "build workflow with module.json configuration" {
    # Create module.json
    local config_file="$TEST_TEMP_DIR/module.json"
    create_test_module_config "$config_file" "corporate" "compose"

    run "$SCRIPT_DIR/build.sh" \
        --config "$config_file" \
        --output "$TEST_OUTPUT_DIR" \
        --force

    [ "$status" -eq 0 ]
    assert_contains "$output" "Module configuration loaded successfully"
}

@test "build workflow handles missing template gracefully" {
    run "$SCRIPT_DIR/build.sh" \
        --template nonexistent \
        --output "$TEST_OUTPUT_DIR" \
        --force

    [ "$status" -eq 1 ]
    assert_contains "$output" "Template 'nonexistent' not found"
    assert_contains "$output" "Available templates:"
}

@test "build workflow validates parameters before execution" {
    # Test validation-only mode
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --theme compose \
        --output "$TEST_OUTPUT_DIR" \
        --validate-only

    [ "$status" -eq 0 ]
    assert_contains "$output" "Parameter validation completed"
    assert_contains "$output" "Validation completed successfully"

    # Output directory should not be created in validation-only mode
    [[ ! -d "$TEST_OUTPUT_DIR" ]]
}

@test "build workflow respects force flag for existing output" {
    # Create existing output directory
    mkdir -p "$TEST_OUTPUT_DIR"
    echo "existing content" > "$TEST_OUTPUT_DIR/existing.txt"

    # Without force flag, should fail or warn
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR"

    # May fail or succeed with warning, depending on implementation
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]

    # With force flag, should succeed
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --force

    [ "$status" -eq 0 ]
}

@test "build workflow handles components processing" {
    # Corporate template should have components.yml
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --force \
        --verbose

    [ "$status" -eq 0 ]

    # Should mention component processing
    assert_contains "$output" "components" || assert_contains "$output" "quiz-engine"
}

@test "build workflow provides comprehensive error information" {
    # Test with missing dependency (remove Hugo mock temporarily)
    mv "$TEST_TEMP_DIR/bin/hugo" "$TEST_TEMP_DIR/bin/hugo.bak"

    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR"

    [ "$status" -eq 1 ]

    # Should provide structured error information with enhanced v2.0 messages
    assert_contains "$output" "Hugo is not installed" || assert_contains "$output" "Command not found"

    # Restore Hugo mock
    mv "$TEST_TEMP_DIR/bin/hugo.bak" "$TEST_TEMP_DIR/bin/hugo"
}

@test "build workflow supports debug mode" {
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --debug \
        --force

    [ "$status" -eq 0 ]

    # Debug mode might provide additional output
    # This test ensures debug mode doesn't break the build
}

@test "build workflow handles environment configuration" {
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --environment production \
        --force

    [ "$status" -eq 0 ]
    assert_contains "$output" "Environment: production"
}

@test "build workflow processes malformed module.json gracefully" {
    # Create malformed config
    local config_file="$TEST_TEMP_DIR/malformed.json"
    simulate_malformed_json "$config_file"

    run "$SCRIPT_DIR/build.sh" \
        --config "$config_file" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --force

    [ "$status" -eq 1 ]
    assert_contains "$output" "parsing" || assert_contains "$output" "CONFIG"
}

@test "build workflow shows helpful usage information" {
    # Test help flag
    run "$SCRIPT_DIR/build.sh" --help

    [ "$status" -eq 0 ]
    assert_contains "$output" "Usage" || assert_contains "$output" "template"
    assert_contains "$output" "Hugo Template Factory"
}

@test "build workflow handles permission errors gracefully" {
    # Create output directory with restricted permissions
    mkdir -p "$TEST_OUTPUT_DIR"
    chmod 555 "$TEST_OUTPUT_DIR"

    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --force

    # Should handle permission error gracefully
    [ "$status" -eq 1 ]
    assert_contains "$output" "permission" || assert_contains "$output" "IO"

    # Restore permissions for cleanup
    chmod 755 "$TEST_OUTPUT_DIR"
}

@test "build workflow preserves error context through full execution" {
    # This test ensures error context is properly managed throughout
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --force \
        --debug

    [ "$status" -eq 0 ]

    # Should complete without context leakage errors
    assert_not_contains "$output" "context leak"
}

@test "build workflow performance is within acceptable limits" {
    # Benchmark full build workflow
    local duration_ms
    duration_ms=$(time_command "$SCRIPT_DIR/build.sh --template corporate --output $TEST_OUTPUT_DIR --force")

    # Full build should complete within reasonable time (adjust threshold as needed)
    assert_performance_threshold "$duration_ms" 30000 "full build workflow"  # 30 seconds
}

@test "build workflow generates expected output structure" {
    run "$SCRIPT_DIR/build.sh" \
        --template corporate \
        --output "$TEST_OUTPUT_DIR" \
        --force

    [ "$status" -eq 0 ]

    # Check that Hugo-style output was generated
    # (This depends on the actual Hugo execution and output structure)
    assert_directory_exists "$TEST_OUTPUT_DIR"

    # The exact structure depends on Hugo execution, but there should be files
    local file_count=$(find "$TEST_OUTPUT_DIR" -type f 2>/dev/null | wc -l)
    [ "$file_count" -gt 0 ]
}

@test "build workflow handles concurrent execution gracefully" {
    # Test that multiple builds don't interfere with each other
    # (This is important for CI/CD environments)

    local output1="$TEST_TEMP_DIR/output1"
    local output2="$TEST_TEMP_DIR/output2"

    # Start first build
    "$SCRIPT_DIR/build.sh" --template corporate --output "$output1" --force &
    local pid1=$!

    # Start second build
    "$SCRIPT_DIR/build.sh" --template minimal --output "$output2" --force &
    local pid2=$!

    # Wait for both to complete
    wait $pid1
    local status1=$?
    wait $pid2
    local status2=$?

    # Both should succeed
    [ "$status1" -eq 0 ]
    [ "$status2" -eq 0 ]

    # Both output directories should exist
    assert_directory_exists "$output1"
    assert_directory_exists "$output2"
}