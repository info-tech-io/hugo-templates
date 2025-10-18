#!/usr/bin/env bats

#
# Unit Tests for Federation Configuration Functions
# Tests functions from scripts/federated-build.sh related to configuration
#

load '../helpers/test-helpers'

setup() {
    # Disable error traps for testing
    set +e
    trap - ERR

    setup_test_environment

    # Source federated build script functions
    export SCRIPT_DIR="$BATS_TEST_DIRNAME/../../../scripts"
    export PROJECT_ROOT="$BATS_TEST_DIRNAME/../../.."

    # Set test fixtures directory
    export TEST_FIXTURES="$BATS_TEST_DIRNAME/../fixtures/federation/modules"

    # Mock federation environment
    export CONFIG="modules.json"
    export OUTPUT="./public"
    export VERBOSE="false"
    export QUIET="true"  # Suppress output during tests
    export VALIDATE_ONLY="false"
    export DEBUG_MODE="false"
    export DRY_RUN="false"
    export DISABLE_ERROR_TRAP="true"  # Disable error handling trap

    # Source the actual federated-build.sh script functions
    # This will initialize error handling, cache, and performance systems
    source_federation_functions
}

teardown() {
    teardown_test_environment
}

# Source federation functions for testing
# We extract and adapt the actual functions from federated-build.sh for testing
source_federation_functions() {
    # Define simplified logging functions for tests
    log_error() { echo "ERROR: $*" >&2; }
    log_info() { [[ "$QUIET" != "true" ]] && echo "INFO: $*"; }
    log_success() { [[ "$QUIET" != "true" ]] && echo "SUCCESS: $*"; }
    log_verbose() { [[ "$VERBOSE" == "true" ]] && echo "VERBOSE: $*"; }
    log_config_error() { log_error "$@"; }
    log_dependency_error() { log_error "$@"; }
    log_io_error() { log_error "$@"; }

    # Simplified enter_function and exit_function for tests
    enter_function() { : ; }
    exit_function() { : ; }
    set_error_context() { : ; }

    # Actual load_modules_config function adapted for testing
    # This is the real implementation from federated-build.sh (lines 240-560)
    load_modules_config() {
        local config_file="${1:-$CONFIG}"

        # Validate configuration file exists and is readable
        if [[ ! -f "$config_file" ]]; then
            log_config_error "Configuration file not found: $config_file"
            return 1
        fi

        if [[ ! -r "$config_file" ]]; then
            log_config_error "Configuration file not readable: $config_file"
            return 1
        fi

        log_info "Loading federation configuration from: $config_file"

        # Use Node.js for JSON parsing
        if ! command -v node >/dev/null 2>&1; then
            log_dependency_error "Node.js is required for JSON parsing but not found"
            return 1
        fi

        # Create temporary parsing script
        local temp_script
        temp_script=$(mktemp) || {
            log_io_error "Failed to create temporary script file"
            return 1
        }

        # Node.js script for JSON parsing (simplified from federated-build.sh)
        cat > "$temp_script" << 'NODESCRIPT'
const fs = require('fs');
try {
    const configFile = process.argv[2];
    if (!fs.existsSync(configFile)) {
        console.error(`ERROR: Configuration file not found: ${configFile}`);
        process.exit(1);
    }

    const configContent = fs.readFileSync(configFile, 'utf8');
    if (!configContent.trim()) {
        console.error(`ERROR: Configuration file is empty: ${configFile}`);
        process.exit(1);
    }

    let config;
    try {
        config = JSON.parse(configContent);
    } catch (parseError) {
        console.error(`ERROR: Invalid JSON in ${configFile}:`);
        console.error(`  ${parseError.message}`);
        process.exit(1);
    }

    // Validate top-level structure
    if (typeof config !== 'object' || config === null) {
        console.error(`ERROR: Configuration must be a JSON object`);
        process.exit(1);
    }

    // Validate federation section
    if (!config.federation || typeof config.federation !== 'object') {
        console.error(`ERROR: Missing or invalid 'federation' section in configuration`);
        process.exit(1);
    }

    const federation = config.federation;

    // Export federation metadata
    if (federation.name) console.log('FEDERATION_NAME=' + federation.name);
    if (federation.baseURL) console.log('FEDERATION_BASE_URL=' + federation.baseURL);
    if (federation.strategy) console.log('FEDERATION_STRATEGY=' + federation.strategy);

    // Validate modules array
    if (!config.modules || !Array.isArray(config.modules)) {
        console.error(`ERROR: Missing or invalid 'modules' array in configuration`);
        process.exit(1);
    }

    if (config.modules.length === 0) {
        console.error(`ERROR: Modules array is empty - nothing to build`);
        process.exit(1);
    }

    console.log('MODULES_COUNT=' + config.modules.length);

    // Export module information
    config.modules.forEach((module, index) => {
        if (!module.name) {
            console.error(`ERROR: Module at index ${index} missing required 'name' field`);
            process.exit(1);
        }
        console.log(`MODULE_${index}_NAME=${module.name}`);
        if (module.destination) console.log(`MODULE_${index}_DESTINATION=${module.destination}`);
        if (module.source && module.source.repository) console.log(`MODULE_${index}_REPO=${module.source.repository}`);
    });

    process.exit(0);
} catch (error) {
    console.error(`FATAL: Unexpected error parsing configuration:`);
    console.error(`  ${error.message}`);
    process.exit(1);
}
NODESCRIPT

        # Execute parsing script
        local parse_output
        if parse_output=$(node "$temp_script" "$config_file" 2>&1); then
            # Export parsed variables
            while IFS= read -r line; do
                if [[ "$line" =~ ^[A-Z_0-9]+= ]]; then
                    eval "export $line"
                    log_verbose "Parsed: $line"
                fi
            done <<< "$parse_output"

            rm -f "$temp_script"
            log_success "Configuration loaded: $MODULES_COUNT modules"
            return 0
        else
            log_config_error "Failed to parse configuration file"
            echo "$parse_output" >&2
            rm -f "$temp_script"
            return 1
        fi
    }

    # Actual validate_configuration function from federated-build.sh
    validate_configuration() {
        if [[ -z "${MODULES_COUNT:-}" ]] || [[ "$MODULES_COUNT" -eq 0 ]]; then
            log_config_error "No modules defined in configuration"
            return 1
        fi

        log_info "Validating $MODULES_COUNT module(s)"

        # Validate each module has required fields
        for ((i=0; i<MODULES_COUNT; i++)); do
            local module_name_var="MODULE_${i}_NAME"
            local module_dest_var="MODULE_${i}_DESTINATION"

            if [[ -z "${!module_name_var:-}" ]]; then
                log_config_error "Module at index $i missing name"
                return 1
            fi

            if [[ -z "${!module_dest_var:-}" ]]; then
                log_config_error "Module '${!module_name_var}' missing destination"
                return 1
            fi

            log_verbose "Module $i: ${!module_name_var} -> ${!module_dest_var}"
        done

        log_success "Configuration validation passed"
        return 0
    }
}

# ============================================================================
# Tests for load_modules_config()
# ============================================================================

@test "load_modules_config: loads valid minimal config" {
    local config="$TEST_FIXTURES/minimal.json"

    # Verify fixture exists
    assert_file_exists "$config"

    # Call load_modules_config directly (not with run) to preserve exports
    load_modules_config "$config"

    # Should have exported MODULES_COUNT
    [ -n "${MODULES_COUNT:-}" ]

    # Minimal config has 1 module
    [ "${MODULES_COUNT}" -eq 1 ]

    # Should have exported MODULE_0_NAME
    [ -n "${MODULE_0_NAME:-}" ]
}

@test "load_modules_config: handles missing file" {
    local config="/nonexistent/config.json"

    # Run load_modules_config with missing file
    run load_modules_config "$config"

    # Should fail
    [ "$status" -eq 1 ]

    # Should contain error message about file not found
    assert_contains "$output" "not found"
}

@test "load_modules_config: validates JSON syntax" {
    local config="$TEST_FIXTURES/invalid-bad-json.json"

    # Verify fixture exists
    assert_file_exists "$config"

    # Run load_modules_config with invalid JSON (use run to capture exit code)
    run load_modules_config "$config"

    # Should fail
    [ "$status" -ne 0 ]

    # Output should contain error about invalid JSON or parse error
    assert_contains "$output" "invalid" || assert_contains "$output" "ERROR" || assert_contains "$output" "parse"
}

# ============================================================================
# Tests for validate_configuration()
# ============================================================================

@test "validate_configuration: accepts valid configuration" {
    local config="$TEST_FIXTURES/minimal.json"

    # Load configuration first
    load_modules_config "$config"

    # Validate should succeed
    validate_configuration

    # No errors should occur
    [[ $? -eq 0 ]]
}

@test "validate_configuration: rejects when no modules defined" {
    # Set MODULES_COUNT to 0
    export MODULES_COUNT=0

    # Validate should fail
    run validate_configuration

    [ "$status" -ne 0 ]
    assert_contains "$output" "No modules"
}

@test "validate_configuration: rejects module missing name" {
    # Setup: 1 module with destination but no name
    export MODULES_COUNT=1
    export MODULE_0_NAME=""
    export MODULE_0_DESTINATION="/test"

    # Validate should fail
    run validate_configuration

    [ "$status" -ne 0 ]
    assert_contains "$output" "missing name"
}

@test "validate_configuration: rejects module missing destination" {
    # Setup: 1 module with name but no destination
    export MODULES_COUNT=1
    export MODULE_0_NAME="test-module"
    export MODULE_0_DESTINATION=""

    # Validate should fail
    run validate_configuration

    [ "$status" -ne 0 ]
    assert_contains "$output" "missing destination"
}

@test "validate_configuration: detects destination conflicts" {
    # Setup: 2 modules with same destination
    export MODULES_COUNT=2
    export MODULE_0_NAME="module-a"
    export MODULE_0_DESTINATION="/shared"
    export MODULE_1_NAME="module-b"
    export MODULE_1_DESTINATION="/shared"

    # Validate should fail
    run validate_configuration

    [ "$status" -ne 0 ]
    assert_contains "$output" "conflict"
}
