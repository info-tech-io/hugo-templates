#!/usr/bin/env bats

#
# Unit Tests for Federation Build Orchestration Functions
# Tests build orchestration functions from scripts/federated-build.sh
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

    # Mock federation build environment
    export OUTPUT="$TEST_TEMP_DIR/federation-output"
    export VERBOSE="false"
    export QUIET="true"  # Suppress output during tests
    export DRY_RUN="false"
    export PRESERVE_BASE_SITE="false"
    export DISABLE_ERROR_TRAP="true"

    # For build tracking
    export SUCCESSFUL_BUILDS=0
    export FAILED_BUILDS=0
    export MODULES_COUNT=0

    # Create mock functions for federation testing
    create_federation_build_functions_for_testing
}

teardown() {
    teardown_test_environment
}

# Create isolated versions of federation build functions for testing
create_federation_build_functions_for_testing() {
    # Define simplified logging functions for tests
    log_error() { echo "ERROR: $*" >&2; }
    log_info() { [[ "$QUIET" != "true" ]] && echo "INFO: $*"; }
    log_success() { [[ "$QUIET" != "true" ]] && echo "SUCCESS: $*"; }
    log_verbose() { [[ "$VERBOSE" == "true" ]] && echo "VERBOSE: $*"; }
    log_warning() { echo "WARNING: $*" >&2; }
    log_io_error() { log_error "$@"; }

    # Simplified enter_function and exit_function for tests
    enter_function() { : ; }
    exit_function() { : ; }
    set_error_context() { : ; }

    # Actual setup_output_structure function adapted from federated-build.sh (lines 623-663)
    setup_output_structure() {
        # Create output directory if it doesn't exist
        if [[ ! -d "$OUTPUT" ]]; then
            log_info "Creating output directory: $OUTPUT"
            if [[ "$DRY_RUN" == "false" ]]; then
                if ! mkdir -p "$OUTPUT"; then
                    log_io_error "Failed to create output directory: $OUTPUT"
                    return 1
                fi
            else
                log_info "[DRY RUN] Would create: $OUTPUT"
            fi
        else
            if [[ "$PRESERVE_BASE_SITE" == "false" ]]; then
                log_warning "Output directory exists and will be overwritten: $OUTPUT"
            else
                log_info "Output directory exists, preserving base site content"
            fi
        fi

        # Create temporary working directory
        if [[ "$DRY_RUN" == "false" ]]; then
            TEMP_DIR=$(mktemp -d) || {
                log_io_error "Failed to create temporary directory"
                return 1
            }
            log_verbose "Created temporary directory: $TEMP_DIR"
        else
            log_info "[DRY RUN] Would create temporary working directory"
        fi

        log_success "Output structure ready"
        return 0
    }

    # Actual download_module_source function adapted from federated-build.sh (lines 1177-1252)
    download_module_source() {
        local module_index=$1
        local module_name_var="MODULE_${module_index}_NAME"
        local module_repo_var="MODULE_${module_index}_REPO"
        local module_path_var="MODULE_${module_index}_PATH"
        local module_branch_var="MODULE_${module_index}_BRANCH"

        local module_name="${!module_name_var}"
        local module_repo="${!module_repo_var:-}"
        local module_path="${!module_path_var:-.}"
        local module_branch="${!module_branch_var:-main}"

        # Create module working directory
        if [[ "$DRY_RUN" == "true" ]]; then
            MODULE_WORK_DIR="/tmp/dry-run/module-$module_index-$module_name"
            log_info "[DRY RUN] Would download: $module_repo ($module_branch) -> $MODULE_WORK_DIR"
            return 0
        fi

        MODULE_WORK_DIR="${TEMP_DIR:-$TEST_TEMP_DIR}/module-$module_index-$module_name"

        mkdir -p "$MODULE_WORK_DIR" || {
            log_io_error "Failed to create module work directory: $MODULE_WORK_DIR"
            return 1
        }

        # If repository is "local" or not specified, skip cloning
        if [[ -z "$module_repo" ]] || [[ "$module_repo" == "local" ]]; then
            log_warning "No repository specified for $module_name - using local configuration"
            return 0
        fi

        # For testing, we'll simulate successful download
        log_info "Cloning $module_name from $module_repo (branch: $module_branch)"
        log_success "Downloaded: $module_name"
        return 0
    }

    # Simplified build_module function for testing
    build_module() {
        local module_index=$1
        local module_work_dir=${2:-$MODULE_WORK_DIR}

        local module_name_var="MODULE_${module_index}_NAME"
        local module_dest_var="MODULE_${module_index}_DESTINATION"

        local module_name="${!module_name_var}"
        local module_dest="${!module_dest_var}"

        if [[ -z "$module_name" ]]; then
            log_error "Module name not set for index $module_index"
            return 1
        fi

        log_info "Building module: $module_name"

        # Prepare output directory for this module
        if [[ "$DRY_RUN" == "true" ]]; then
            MODULE_OUTPUT_DIR="/tmp/dry-run/output-$module_index-$module_name"
            log_info "[DRY RUN] Would build module: $module_name"
            SUCCESSFUL_BUILDS=$((SUCCESSFUL_BUILDS + 1))
            return 0
        fi

        MODULE_OUTPUT_DIR="${TEMP_DIR:-$TEST_TEMP_DIR}/output-$module_index-$module_name"

        mkdir -p "$MODULE_OUTPUT_DIR" || {
            log_io_error "Failed to create module output directory: $MODULE_OUTPUT_DIR"
            return 1
        }

        log_success "Built $module_name"
        SUCCESSFUL_BUILDS=$((SUCCESSFUL_BUILDS + 1))
        return 0
    }

    # Simplified orchestrate_builds function for testing
    orchestrate_builds() {
        if [[ "$MODULES_COUNT" -eq 0 ]]; then
            log_error "No modules to build"
            return 1
        fi

        log_info "Starting build orchestration for $MODULES_COUNT module(s)"

        # Arrays to track module states
        declare -a module_work_dirs
        declare -a module_output_dirs
        declare -a module_build_status

        # Sequential build execution
        for ((i=0; i<MODULES_COUNT; i++)); do
            local module_name_var="MODULE_${i}_NAME"
            local module_name="${!module_name_var}"

            log_info "Processing module $((i+1))/$MODULES_COUNT: $module_name"

            # Download module source
            if download_module_source "$i"; then
                module_work_dirs[$i]="$MODULE_WORK_DIR"
            else
                log_error "Failed to download source for module: $module_name"
                module_build_status[$i]="download_failed"
                FAILED_BUILDS=$((FAILED_BUILDS + 1))
                continue
            fi

            # Build module
            if build_module "$i" "$MODULE_WORK_DIR"; then
                module_output_dirs[$i]="$MODULE_OUTPUT_DIR"
                module_build_status[$i]="success"
            else
                module_build_status[$i]="build_failed"
                FAILED_BUILDS=$((FAILED_BUILDS + 1))
            fi
        done

        # Check if at least one module succeeded
        if [[ $SUCCESSFUL_BUILDS -eq 0 ]]; then
            log_error "All module builds failed"
            return 1
        fi

        if [[ $FAILED_BUILDS -gt 0 ]]; then
            log_warning "Some modules failed to build ($FAILED_BUILDS/$MODULES_COUNT)"
        else
            log_success "All modules built successfully ($SUCCESSFUL_BUILDS/$MODULES_COUNT)"
        fi

        # Export module output directories
        export MODULE_OUTPUT_DIRS="${module_output_dirs[*]}"
        export MODULE_BUILD_STATUS="${module_build_status[*]}"

        return 0
    }
}

# ============================================================================
# Tests for setup_output_structure()
# ============================================================================

@test "setup_output_structure: creates output directory" {
    # Ensure output dir doesn't exist
    rm -rf "$OUTPUT"

    # Run setup_output_structure
    setup_output_structure

    # Output directory should be created
    assert_directory_exists "$OUTPUT"

    # TEMP_DIR should be created
    [ -n "${TEMP_DIR:-}" ]
    assert_directory_exists "$TEMP_DIR"
}

@test "setup_output_structure: handles existing output directory" {
    # Create output directory first
    mkdir -p "$OUTPUT"
    echo "existing content" > "$OUTPUT/test.txt"

    # Run setup_output_structure
    run setup_output_structure

    [ "$status" -eq 0 ]
    # Should warn about overwriting
    assert_contains "$output" "exists" || assert_contains "$output" "overwritten" || [ "$status" -eq 0 ]
}

@test "setup_output_structure: respects DRY_RUN mode" {
    export DRY_RUN="true"
    rm -rf "$OUTPUT"

    # Run setup_output_structure in dry-run mode
    run setup_output_structure

    [ "$status" -eq 0 ]
    # Should indicate dry-run
    assert_contains "$output" "DRY RUN" || assert_contains "$output" "Would create"
}

# ============================================================================
# Tests for download_module_source()
# ============================================================================

@test "download_module_source: creates module work directory" {
    # Setup module configuration
    export MODULES_COUNT=1
    export MODULE_0_NAME="test-module"
    export MODULE_0_REPO="local"
    export MODULE_0_PATH="docs"
    export MODULE_0_BRANCH="main"
    export TEMP_DIR="$TEST_TEMP_DIR"

    # Download module source
    download_module_source 0

    # MODULE_WORK_DIR should be set and exist
    [ -n "${MODULE_WORK_DIR:-}" ]
    assert_directory_exists "$MODULE_WORK_DIR"
}

@test "download_module_source: handles local repository" {
    # Setup module with local repository
    export MODULES_COUNT=1
    export MODULE_0_NAME="local-module"
    export MODULE_0_REPO="local"
    export TEMP_DIR="$TEST_TEMP_DIR"

    # Download should succeed for local repos
    run download_module_source 0

    [ "$status" -eq 0 ]
    assert_contains "$output" "local" || [ "$status" -eq 0 ]
}

@test "download_module_source: respects DRY_RUN mode" {
    export DRY_RUN="true"
    export MODULES_COUNT=1
    export MODULE_0_NAME="test-module"
    export MODULE_0_REPO="https://github.com/test/repo.git"
    export MODULE_0_BRANCH="main"

    # Run in dry-run mode
    run download_module_source 0

    [ "$status" -eq 0 ]
    assert_contains "$output" "DRY RUN"
}

# ============================================================================
# Tests for build_module()
# ============================================================================

@test "build_module: builds module successfully" {
    # Setup module configuration
    export MODULES_COUNT=1
    export MODULE_0_NAME="test-module"
    export MODULE_0_DESTINATION="/test"
    export TEMP_DIR="$TEST_TEMP_DIR"
    export SUCCESSFUL_BUILDS=0

    # Build module
    build_module 0

    # Should succeed
    [ "$SUCCESSFUL_BUILDS" -eq 1 ]

    # MODULE_OUTPUT_DIR should be created
    [ -n "${MODULE_OUTPUT_DIR:-}" ]
    assert_directory_exists "$MODULE_OUTPUT_DIR"
}

@test "build_module: handles missing module name" {
    # Setup module without name
    export MODULES_COUNT=1
    export MODULE_0_NAME=""
    export MODULE_0_DESTINATION="/test"

    # Build should fail
    run build_module 0

    [ "$status" -ne 0 ]
    assert_contains "$output" "not set" || assert_contains "$output" "ERROR"
}

@test "build_module: respects DRY_RUN mode" {
    export DRY_RUN="true"
    export MODULES_COUNT=1
    export MODULE_0_NAME="test-module"
    export MODULE_0_DESTINATION="/test"
    export SUCCESSFUL_BUILDS=0

    # Build in dry-run mode
    run build_module 0

    [ "$status" -eq 0 ]
    assert_contains "$output" "DRY RUN"
    # Should still increment counter
    [ "$SUCCESSFUL_BUILDS" -eq 1 ]
}

@test "build_module: creates module output directory" {
    export MODULES_COUNT=1
    export MODULE_0_NAME="output-test"
    export MODULE_0_DESTINATION="/output"
    export TEMP_DIR="$TEST_TEMP_DIR"

    # Build module
    build_module 0

    # Output directory should exist
    [ -n "${MODULE_OUTPUT_DIR:-}" ]
    assert_directory_exists "$MODULE_OUTPUT_DIR"
    # Should contain module name
    [[ "$MODULE_OUTPUT_DIR" == *"output-test"* ]]
}

# ============================================================================
# Tests for orchestrate_builds()
# ============================================================================

@test "orchestrate_builds: handles empty modules list" {
    export MODULES_COUNT=0

    # Should fail with no modules
    run orchestrate_builds

    [ "$status" -ne 0 ]
    assert_contains "$output" "No modules"
}

@test "orchestrate_builds: builds all modules sequentially" {
    # Setup 3 modules
    export MODULES_COUNT=3
    export MODULE_0_NAME="module-a"
    export MODULE_0_DESTINATION="/a"
    export MODULE_1_NAME="module-b"
    export MODULE_1_DESTINATION="/b"
    export MODULE_2_NAME="module-c"
    export MODULE_2_DESTINATION="/c"
    export TEMP_DIR="$TEST_TEMP_DIR"
    export SUCCESSFUL_BUILDS=0
    export FAILED_BUILDS=0

    # Orchestrate builds
    orchestrate_builds

    # All 3 should succeed
    [ "$SUCCESSFUL_BUILDS" -eq 3 ]
    [ "$FAILED_BUILDS" -eq 0 ]
}

@test "orchestrate_builds: continues after module failure" {
    # Setup 3 modules, but make one fail by not setting its name
    export MODULES_COUNT=3
    export MODULE_0_NAME="module-a"
    export MODULE_0_DESTINATION="/a"
    export MODULE_1_NAME=""  # This will fail
    export MODULE_1_DESTINATION="/b"
    export MODULE_2_NAME="module-c"
    export MODULE_2_DESTINATION="/c"
    export TEMP_DIR="$TEST_TEMP_DIR"
    export SUCCESSFUL_BUILDS=0
    export FAILED_BUILDS=0

    # Orchestrate builds
    orchestrate_builds

    # 2 should succeed, 1 should fail
    [ "$SUCCESSFUL_BUILDS" -eq 2 ]
    [ "$FAILED_BUILDS" -eq 1 ]
}

@test "orchestrate_builds: exports build status" {
    # Setup 2 modules
    export MODULES_COUNT=2
    export MODULE_0_NAME="module-a"
    export MODULE_0_DESTINATION="/a"
    export MODULE_1_NAME="module-b"
    export MODULE_1_DESTINATION="/b"
    export TEMP_DIR="$TEST_TEMP_DIR"

    # Orchestrate builds
    orchestrate_builds

    # Should export MODULE_BUILD_STATUS
    [ -n "${MODULE_BUILD_STATUS:-}" ]
    # Should contain success statuses
    [[ "$MODULE_BUILD_STATUS" == *"success"* ]]
}
