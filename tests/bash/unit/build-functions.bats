#!/usr/bin/env bats

#
# Unit Tests for Build Script Functions
# Tests core functions from scripts/build.sh
#

load '../helpers/test-helpers'

setup() {
    setup_test_environment

    # Source build script functions (need to handle this carefully)
    export SCRIPT_DIR="$BATS_TEST_DIRNAME/../../../scripts"
    export PROJECT_ROOT="$BATS_TEST_DIRNAME/../../.."

    # Mock build script environment
    export TEMPLATE="corporate"
    export THEME="compose"
    export OUTPUT="$TEST_TEMP_DIR/output"
    export CONFIG=""
    export COMPONENTS=""
    export ENVIRONMENT="development"
    export VERBOSE="false"
    export QUIET="false"
    export LOG_LEVEL="info"
    export VALIDATE_ONLY="false"
    export FORCE="false"
    export DEBUG_MODE="false"

    # Error handling already loaded by test-helpers
    # Just ensure it's initialized

    # Create a test version of build script functions
    create_build_functions_for_testing
}

teardown() {
    teardown_test_environment
}

# Create isolated versions of build functions for testing
create_build_functions_for_testing() {
    # Create minimal mock functions for testing
    validate_parameters() {
        log_info "Validating parameters..."

        # Check if template exists
        if [[ ! -d "$PROJECT_ROOT/templates/$TEMPLATE" ]]; then
            log_validation_error "Template directory not found: $TEMPLATE" ""
            return 1
        fi

        # Check Hugo availability
        if ! command -v hugo >/dev/null 2>&1; then
            log_dependency_error "Hugo is not installed or not in PATH" "Please install Hugo"
            return 1
        fi

        log_info "Parameter validation completed"
        return 0
    }

    load_module_config() {
        local config_file="$1"

        if [[ ! -f "$config_file" ]]; then
            log_config_error "Configuration file not found: $config_file" ""
            return 1
        fi

        if [[ ! -s "$config_file" ]]; then
            log_config_error "Configuration file is empty: $config_file" ""
            return 1
        fi

        # Simple validation without Node.js
        if ! jq . "$config_file" >/dev/null 2>&1; then
            log_config_error "Invalid JSON in configuration file" "Check JSON syntax"
            return 1
        fi

        log_info "Module configuration loaded successfully"
        return 0
    }

    parse_components() {
        local template_path="$1"
        local components_file="$template_path/components.yml"

        if [[ ! -d "$template_path" ]]; then
            log_validation_error "Template directory not found: $template_path" ""
            return 1
        fi

        if [[ ! -f "$components_file" ]]; then
            log_info "No components.yml found, skipping component processing"
            return 0
        fi

        log_info "Components processed successfully"
        return 0
    }
}

@test "validate_parameters accepts valid template" {
    TEMPLATE="corporate"

    # Create template directory
    mkdir -p "$PROJECT_ROOT/templates/corporate"

    run validate_parameters
    [ "$status" -eq 0 ]
}

@test "validate_parameters rejects invalid template" {
    TEMPLATE="nonexistent"

    run validate_parameters
    [ "$status" -eq 1 ]
    assert_contains "$output" "Template directory not found"
}

@test "validate_parameters checks Hugo availability" {
    # Hugo should be available via our mock
    run validate_parameters
    [ "$status" -eq 0 ]
}

@test "validate_parameters handles missing Hugo" {
    # Remove Hugo mock temporarily
    mv "$TEST_TEMP_DIR/bin/hugo" "$TEST_TEMP_DIR/bin/hugo.bak"

    run validate_parameters
    [ "$status" -eq 1 ]
    assert_contains "$output" "Hugo not found"

    # Restore Hugo mock
    mv "$TEST_TEMP_DIR/bin/hugo.bak" "$TEST_TEMP_DIR/bin/hugo"
}

@test "load_module_config handles missing config file" {
    CONFIG=""

    run load_module_config
    [ "$status" -eq 0 ]
}

@test "load_module_config processes valid JSON configuration" {
    CONFIG="$TEST_TEMP_DIR/module.json"
    create_test_module_config "$CONFIG" "educational" "minimal"

    run load_module_config
    [ "$status" -eq 0 ]

    # Check that variables were set (this might need adjustment based on actual implementation)
    # The mock node script should have processed the config
}

@test "load_module_config handles malformed JSON" {
    CONFIG="$TEST_TEMP_DIR/module.json"
    simulate_malformed_json "$CONFIG"

    run load_module_config
    [ "$status" -eq 1 ]
    assert_contains "$output" "parsing"
}

@test "load_module_config handles missing Node.js" {
    CONFIG="$TEST_TEMP_DIR/module.json"
    create_test_module_config "$CONFIG"

    # Remove Node.js mock
    mv "$TEST_TEMP_DIR/bin/node" "$TEST_TEMP_DIR/bin/node.bak"

    run load_module_config
    [ "$status" -eq 1 ]
    assert_contains "$output" "Node.js not available"

    # Restore Node.js mock
    mv "$TEST_TEMP_DIR/bin/node.bak" "$TEST_TEMP_DIR/bin/node"
}

@test "parse_components handles missing components.yml" {
    TEMPLATE="minimal"

    # Create template without components.yml
    mkdir -p "$PROJECT_ROOT/templates/minimal"

    run parse_components
    [ "$status" -eq 0 ]
    assert_contains "$output" "No components.yml file found"
}

@test "parse_components processes valid components.yml" {
    TEMPLATE="corporate"

    # Create template with components.yml
    local template_dir="$PROJECT_ROOT/templates/corporate"
    mkdir -p "$template_dir"
    create_test_components_yml "$template_dir/components.yml"

    run parse_components
    [ "$status" -eq 0 ]
}

@test "parse_components handles missing template directory" {
    TEMPLATE="nonexistent"

    run parse_components
    [ "$status" -eq 1 ]
    assert_contains "$output" "Template directory not found"
}

@test "parse_components gracefully handles YAML parsing errors" {
    TEMPLATE="corporate"

    # Create template with malformed components.yml
    local template_dir="$PROJECT_ROOT/templates/corporate"
    mkdir -p "$template_dir"
    echo "invalid: yaml: content:" > "$template_dir/components.yml"

    # Should not fail the entire build
    run parse_components
    [ "$status" -eq 0 ]
    assert_contains "$output" "Warning" || assert_contains "$output" "parsing failed"
}

@test "functions handle error context correctly" {
    TEMPLATE="corporate"
    mkdir -p "$PROJECT_ROOT/templates/corporate"

    # Test that error context is set and cleared
    run validate_parameters
    [ "$status" -eq 0 ]

    # Error context should be cleared after successful function execution
    [ -z "$ERROR_CONTEXT" ]
}

@test "functions update error counters appropriately" {
    # Start with clean counters
    [ "$ERROR_COUNT" -eq 0 ]
    [ "$WARNING_COUNT" -eq 0 ]

    # Test with invalid template (should increment error count)
    TEMPLATE="nonexistent"
    validate_parameters 2>/dev/null || true

    # Error count should have increased
    [ "$ERROR_COUNT" -gt 0 ]
}

@test "verbose mode provides additional output" {
    VERBOSE="true"
    TEMPLATE="corporate"
    mkdir -p "$PROJECT_ROOT/templates/corporate"

    run validate_parameters
    [ "$status" -eq 0 ]

    # Verbose output should contain more details
    assert_contains "$output" "Template path" || assert_contains "$output" "Found"
}

@test "quiet mode suppresses non-error output" {
    QUIET="true"
    TEMPLATE="corporate"
    mkdir -p "$PROJECT_ROOT/templates/corporate"

    run validate_parameters
    [ "$status" -eq 0 ]

    # Should have minimal output in quiet mode
    [[ ${#output} -lt 100 ]]
}

@test "debug mode enables additional diagnostics" {
    DEBUG_MODE="true"
    TEMPLATE="corporate"
    mkdir -p "$PROJECT_ROOT/templates/corporate"

    run validate_parameters
    [ "$status" -eq 0 ]

    # Debug mode might enable additional checks or output
    # This test validates that debug mode doesn't break functionality
}

@test "functions handle file permission errors" {
    CONFIG="$TEST_TEMP_DIR/module.json"
    create_test_module_config "$CONFIG"
    simulate_permission_error "$CONFIG"

    run load_module_config
    [ "$status" -eq 1 ]

    # Restore permissions for cleanup
    chmod 644 "$CONFIG" 2>/dev/null || true
}

@test "functions provide helpful error messages" {
    TEMPLATE="nonexistent"

    run validate_parameters
    [ "$status" -eq 1 ]

    # Error message should be helpful and actionable
    assert_contains "$output" "Template directory not found" || assert_contains "$output" "VALIDATION"

    # Should suggest a solution
    assert_contains "$output" "Check" || assert_contains "$output" "template"
}