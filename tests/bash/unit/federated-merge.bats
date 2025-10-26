#!/usr/bin/env bats

#
# Unit Tests for Federation Merge Functions
# Tests download, merge, and deploy functions from scripts/federated-build.sh
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

    # Mock federation merge environment
    export OUTPUT="$TEST_TEMP_DIR/federation-output"
    export MERGE_STRATEGY="overwrite"
    export VERBOSE="false"
    export QUIET="true"  # Suppress output during tests
    export DRY_RUN="false"
    export DISABLE_ERROR_TRAP="true"

    # For tracking
    export MODULES_COUNT=0
    export SUCCESSFUL_BUILDS=0
    export FAILED_BUILDS=0

    # Create mock functions for federation testing
    create_federation_merge_functions_for_testing
}

teardown() {
    teardown_test_environment
}

# Create isolated versions of federation merge functions for testing
create_federation_merge_functions_for_testing() {
    # Define simplified logging functions for tests
    log_error() { echo "ERROR: $*" >&2; }
    log_info() { [[ "$QUIET" != "true" ]] && echo "INFO: $*"; }
    log_success() { [[ "$QUIET" != "true" ]] && echo "SUCCESS: $*"; }
    log_verbose() { [[ "$VERBOSE" == "true" ]] && echo "VERBOSE: $*"; }
    log_warning() { echo "WARNING: $*" >&2; }

    # Simplified enter_function and exit_function for tests
    enter_function() { : ; }
    exit_function() { : ; }
    set_error_context() { : ; }

    # Actual detect_merge_conflicts function adapted from federated-build.sh (lines 1511-1567)
    detect_merge_conflicts() {
        local existing_dir="$1"
        local new_dir="$2"
        local -n conflicts_array="$3"

        # Check if directories exist
        if [[ ! -d "$existing_dir" ]]; then
            log_verbose "No existing content - no conflicts possible"
            return 0
        fi

        if [[ ! -d "$new_dir" ]]; then
            log_error "New content directory not found: $new_dir"
            return 1
        fi

        local conflict_count=0

        # Find all files/directories in new content
        while IFS= read -r new_item; do
            # Get relative path
            local rel_path="${new_item#$new_dir/}"

            # Check if exists in existing content
            local existing_item="$existing_dir/$rel_path"

            if [[ -e "$existing_item" ]]; then
                # Conflict detected
                conflicts_array+=("$rel_path")
                ((conflict_count++))

                # Determine conflict type
                if [[ -f "$new_item" ]] && [[ -f "$existing_item" ]]; then
                    log_verbose "  File conflict: $rel_path"
                elif [[ -d "$new_item" ]] && [[ -d "$existing_item" ]]; then
                    log_verbose "  Directory conflict: $rel_path (may contain sub-conflicts)"
                else
                    log_verbose "  Type conflict: $rel_path (file vs directory)"
                fi
            fi
        done < <(find "$new_dir" -mindepth 1 2>/dev/null)

        if [[ $conflict_count -gt 0 ]]; then
            log_warning "Detected $conflict_count potential merge conflicts"
            return 1
        else
            log_success "No merge conflicts detected"
            return 0
        fi
    }

    # Actual merge_with_strategy function adapted from federated-build.sh (lines 1576-1692)
    merge_with_strategy() {
        local source_dir="$1"
        local target_dir="$2"
        local strategy="${3:-overwrite}"

        log_info "Applying merge strategy: $strategy"
        log_verbose "  Source: $source_dir"
        log_verbose "  Target: $target_dir"

        # Detect conflicts first
        declare -a conflicts=()
        detect_merge_conflicts "$target_dir" "$source_dir" conflicts
        local has_conflicts=$?

        # Apply strategy
        case "$strategy" in
            overwrite)
                log_info "Strategy: Overwrite - new content replaces existing"

                if [[ $has_conflicts -eq 1 ]]; then
                    log_warning "Overwriting ${#conflicts[@]} conflicting items"
                fi

                # Use rsync if available, otherwise cp
                if command -v rsync >/dev/null 2>&1; then
                    rsync -a --delete-during "$source_dir/" "$target_dir/" 2>/dev/null || true
                else
                    cp -rf "$source_dir"/* "$target_dir/" 2>/dev/null || true
                fi
                ;;

            preserve)
                log_info "Strategy: Preserve - keep existing, skip conflicting new content"

                if [[ $has_conflicts -eq 1 ]]; then
                    log_warning "Preserving ${#conflicts[@]} existing items, skipping new versions"
                fi

                # Copy only non-conflicting files
                if command -v rsync >/dev/null 2>&1; then
                    rsync -a --ignore-existing "$source_dir/" "$target_dir/" 2>/dev/null || true
                else
                    # Fallback: manual copy of non-conflicting files
                    find "$source_dir" -type f 2>/dev/null | while IFS= read -r source_file; do
                        local rel_path="${source_file#$source_dir/}"
                        local target_file="$target_dir/$rel_path"

                        if [[ ! -e "$target_file" ]]; then
                            mkdir -p "$(dirname "$target_file")"
                            cp "$source_file" "$target_file" 2>/dev/null || true
                        fi
                    done
                fi
                ;;

            merge)
                log_info "Strategy: Merge - combine compatible content"

                # For directories: recursive merge
                find "$source_dir" -type f 2>/dev/null | while IFS= read -r source_file; do
                    local rel_path="${source_file#$source_dir/}"
                    local target_file="$target_dir/$rel_path"

                    if [[ ! -e "$target_file" ]]; then
                        # No conflict - copy directly
                        mkdir -p "$(dirname "$target_file")"
                        cp "$source_file" "$target_file" 2>/dev/null || true
                    elif [[ -f "$target_file" ]]; then
                        # Both exist - attempt merge based on file type
                        if [[ "$source_file" =~ \.(html|htm|xml|txt)$ ]]; then
                            log_warning "Merging text file: $rel_path (experimental)"
                            cat "$source_file" >> "$target_file" 2>/dev/null || true
                        else
                            # Binary or unknown - overwrite
                            log_verbose "Overwriting non-mergeable file: $rel_path"
                            cp "$source_file" "$target_file" 2>/dev/null || true
                        fi
                    fi
                done
                ;;

            error)
                log_info "Strategy: Error - fail on any conflict"

                if [[ $has_conflicts -eq 1 ]]; then
                    log_error "Merge conflicts detected with 'error' strategy"
                    log_error "Conflicting paths:"
                    for conflict in "${conflicts[@]}"; do
                        log_error "  - $conflict"
                    done
                    return 1
                fi

                # No conflicts - safe to merge
                cp -r "$source_dir"/* "$target_dir"/ 2>/dev/null || true
                ;;

            *)
                log_error "Unknown merge strategy: $strategy"
                return 1
                ;;
        esac

        log_success "Merge completed with strategy: $strategy"
        return 0
    }

    # Simplified merge_federation_output function for testing
    merge_federation_output() {
        log_info "Merging module outputs into federation structure"

        if [[ "$MODULES_COUNT" -eq 0 ]]; then
            log_error "No modules to merge"
            return 1
        fi

        # Convert exported space-separated strings back to arrays
        local -a output_dirs
        local -a build_status
        read -ra output_dirs <<< "${MODULE_OUTPUT_DIRS:-}"
        read -ra build_status <<< "${MODULE_BUILD_STATUS:-}"

        local merged_count=0
        local skipped_count=0

        # Process each module
        for ((i=0; i<MODULES_COUNT; i++)); do
            local module_name_var="MODULE_${i}_NAME"
            local module_dest_var="MODULE_${i}_DESTINATION"
            local module_strategy_var="MODULE_${i}_MERGE_STRATEGY"

            local module_name="${!module_name_var}"
            local module_dest="${!module_dest_var:-/}"
            local module_strategy="${!module_strategy_var:-overwrite}"

            # Skip failed builds
            if [[ "${build_status[$i]:-}" != "success" ]]; then
                log_warning "Skipping merge for failed module: $module_name"
                skipped_count=$((skipped_count + 1))
                continue
            fi

            local module_output="${output_dirs[$i]:-}"

            # Determine target directory
            local dest_path="${module_dest#/}"
            local target_dir="$OUTPUT"

            if [[ -n "$dest_path" && "$dest_path" != "/" ]]; then
                target_dir="$OUTPUT/$dest_path"
            fi

            log_info "Merging $module_name → $target_dir (strategy: $module_strategy)"

            # Create target directory
            if ! mkdir -p "$target_dir"; then
                log_error "Failed to create target directory: $target_dir"
                continue
            fi

            # Apply intelligent merge with strategy
            if [[ -n "$module_output" ]] && [[ -d "$module_output" ]]; then
                if merge_with_strategy "$module_output" "$target_dir" "$module_strategy"; then
                    log_success "Merged $module_name successfully"
                    merged_count=$((merged_count + 1))
                else
                    log_error "Failed to merge module: $module_name"
                fi
            fi
        done

        log_info "Merge summary:"
        log_info "  - Modules merged: $merged_count"
        log_info "  - Modules skipped: $skipped_count"

        if [[ $merged_count -eq 0 ]]; then
            log_error "No modules were merged successfully"
            return 1
        fi

        return 0
    }
}

# ============================================================================
# Tests for detect_merge_conflicts()
# ============================================================================

@test "detect_merge_conflicts: detects file conflicts" {
    # Setup: Create directories with conflicting files
    local existing_dir="$TEST_TEMP_DIR/existing"
    local new_dir="$TEST_TEMP_DIR/new"

    mkdir -p "$existing_dir" "$new_dir"
    echo "existing content" > "$existing_dir/index.html"
    echo "new content" > "$new_dir/index.html"

    # Detect conflicts
    declare -a conflicts=()
    run detect_merge_conflicts "$existing_dir" "$new_dir" conflicts

    # Should detect conflict
    [ "$status" -ne 0 ]
    [ "${#conflicts[@]}" -eq 1 ]
    [[ "${conflicts[0]}" == "index.html" ]]
}

@test "detect_merge_conflicts: no conflicts when new dir is clean" {
    # Setup: Create directories with different files
    local existing_dir="$TEST_TEMP_DIR/existing"
    local new_dir="$TEST_TEMP_DIR/new"

    mkdir -p "$existing_dir" "$new_dir"
    echo "existing" > "$existing_dir/file1.txt"
    echo "new" > "$new_dir/file2.txt"

    # Detect conflicts
    declare -a conflicts=()
    run detect_merge_conflicts "$existing_dir" "$new_dir" conflicts

    # Should have no conflicts
    [ "$status" -eq 0 ]
    [ "${#conflicts[@]}" -eq 0 ]
}

@test "detect_merge_conflicts: handles missing existing directory" {
    # Setup: Only new directory
    local existing_dir="$TEST_TEMP_DIR/nonexistent"
    local new_dir="$TEST_TEMP_DIR/new"

    mkdir -p "$new_dir"
    echo "new content" > "$new_dir/file.txt"

    # Detect conflicts
    declare -a conflicts=()
    run detect_merge_conflicts "$existing_dir" "$new_dir" conflicts

    # Should succeed with no conflicts (no existing content)
    [ "$status" -eq 0 ]
}

@test "detect_merge_conflicts: handles missing new directory" {
    # Setup: Only existing directory
    local existing_dir="$TEST_TEMP_DIR/existing"
    local new_dir="$TEST_TEMP_DIR/nonexistent"

    mkdir -p "$existing_dir"
    echo "existing" > "$existing_dir/file.txt"

    # Detect conflicts
    declare -a conflicts=()
    run detect_merge_conflicts "$existing_dir" "$new_dir" conflicts

    # Should fail (new dir not found)
    [ "$status" -ne 0 ]
}

@test "detect_merge_conflicts: detects multiple conflicts" {
    # Setup: Multiple conflicting files
    local existing_dir="$TEST_TEMP_DIR/existing"
    local new_dir="$TEST_TEMP_DIR/new"

    mkdir -p "$existing_dir" "$new_dir"
    echo "old" > "$existing_dir/a.txt"
    echo "old" > "$existing_dir/b.txt"
    echo "old" > "$existing_dir/c.txt"
    echo "new" > "$new_dir/a.txt"
    echo "new" > "$new_dir/b.txt"
    echo "new" > "$new_dir/c.txt"

    # Detect conflicts
    declare -a conflicts=()
    detect_merge_conflicts "$existing_dir" "$new_dir" conflicts

    # Should detect all 3 conflicts
    [ "${#conflicts[@]}" -eq 3 ]
}

# ============================================================================
# Tests for merge_with_strategy()
# ============================================================================

@test "merge_with_strategy: overwrite strategy replaces files" {
    # Setup: Create source and target with conflicting file
    local source="$TEST_TEMP_DIR/source"
    local target="$TEST_TEMP_DIR/target"

    mkdir -p "$source" "$target"
    echo "old content" > "$target/index.html"
    echo "new content" > "$source/index.html"

    # Merge with overwrite strategy
    merge_with_strategy "$source" "$target" "overwrite"

    # Target should have new content
    assert_file_contains "$target/index.html" "new content"
}

@test "merge_with_strategy: preserve strategy keeps existing files" {
    # Setup: Create source and target with conflicting file
    local source="$TEST_TEMP_DIR/source"
    local target="$TEST_TEMP_DIR/target"

    mkdir -p "$source" "$target"
    echo "old content" > "$target/index.html"
    echo "new content" > "$source/index.html"

    # Merge with preserve strategy
    merge_with_strategy "$source" "$target" "preserve"

    # Target should keep old content
    assert_file_contains "$target/index.html" "old content"
}

@test "merge_with_strategy: preserve strategy copies new files" {
    # Setup: Source has file that target doesn't
    local source="$TEST_TEMP_DIR/source"
    local target="$TEST_TEMP_DIR/target"

    mkdir -p "$source" "$target"
    echo "existing" > "$target/old.html"
    echo "new file" > "$source/new.html"

    # Merge with preserve strategy
    merge_with_strategy "$source" "$target" "preserve"

    # Target should have both files
    assert_file_exists "$target/old.html"
    assert_file_exists "$target/new.html"
}

@test "merge_with_strategy: error strategy fails on conflicts" {
    # Setup: Create conflicting files
    local source="$TEST_TEMP_DIR/source"
    local target="$TEST_TEMP_DIR/target"

    mkdir -p "$source" "$target"
    echo "old" > "$target/file.txt"
    echo "new" > "$source/file.txt"

    # Merge with error strategy should fail
    run merge_with_strategy "$source" "$target" "error"

    [ "$status" -ne 0 ]
    assert_contains "$output" "conflict"
}

@test "merge_with_strategy: error strategy succeeds without conflicts" {
    # Setup: No conflicts
    local source="$TEST_TEMP_DIR/source"
    local target="$TEST_TEMP_DIR/target"

    mkdir -p "$source" "$target"
    echo "file1" > "$target/file1.txt"
    echo "file2" > "$source/file2.txt"

    # Merge with error strategy should succeed
    run merge_with_strategy "$source" "$target" "error"

    [ "$status" -eq 0 ]
    assert_file_exists "$target/file2.txt"
}

@test "merge_with_strategy: merge strategy combines files" {
    # Setup: Both directories have files
    local source="$TEST_TEMP_DIR/source"
    local target="$TEST_TEMP_DIR/target"

    mkdir -p "$source" "$target"
    echo "old" > "$target/common.html"
    echo "new" > "$source/common.html"
    echo "unique" > "$source/unique.html"

    # Merge with merge strategy
    run merge_with_strategy "$source" "$target" "merge"

    [ "$status" -eq 0 ]
    # Should have both files
    assert_file_exists "$target/common.html"
    assert_file_exists "$target/unique.html"
}

@test "merge_with_strategy: rejects unknown strategy" {
    local source="$TEST_TEMP_DIR/source"
    local target="$TEST_TEMP_DIR/target"

    mkdir -p "$source" "$target"

    # Unknown strategy should fail
    run merge_with_strategy "$source" "$target" "invalid-strategy"

    [ "$status" -ne 0 ]
    assert_contains "$output" "Unknown"
}

# ============================================================================
# Tests for merge_federation_output()
# ============================================================================

@test "merge_federation_output: handles empty modules list" {
    export MODULES_COUNT=0

    # Should fail with no modules
    run merge_federation_output

    [ "$status" -ne 0 ]
    assert_contains "$output" "No modules"
}

@test "merge_federation_output: merges single module" {
    # Setup: 1 successful module
    export MODULES_COUNT=1
    export MODULE_0_NAME="test-module"
    export MODULE_0_DESTINATION="/"

    # Create module output
    local module_output="$TEST_TEMP_DIR/module-0-output"
    mkdir -p "$module_output"
    echo "module content" > "$module_output/index.html"

    # Setup arrays
    export MODULE_OUTPUT_DIRS="$module_output"
    export MODULE_BUILD_STATUS="success"

    # Create output directory
    mkdir -p "$OUTPUT"

    # Merge
    merge_federation_output

    # Output should contain merged content
    assert_file_exists "$OUTPUT/index.html"
}

@test "merge_federation_output: merges multiple modules to different destinations" {
    # Setup: 2 modules with different destinations
    export MODULES_COUNT=2
    export MODULE_0_NAME="base-module"
    export MODULE_0_DESTINATION="/"
    export MODULE_1_NAME="quiz-module"
    export MODULE_1_DESTINATION="/quiz"

    # Create module outputs
    local output0="$TEST_TEMP_DIR/module-0-output"
    local output1="$TEST_TEMP_DIR/module-1-output"

    mkdir -p "$output0" "$output1"
    echo "base content" > "$output0/index.html"
    echo "quiz content" > "$output1/quiz.html"

    # Setup arrays
    export MODULE_OUTPUT_DIRS="$output0 $output1"
    export MODULE_BUILD_STATUS="success success"

    # Create output directory
    mkdir -p "$OUTPUT"

    # Merge
    merge_federation_output

    # Both should be present at correct paths
    assert_file_exists "$OUTPUT/index.html"
    assert_file_exists "$OUTPUT/quiz/quiz.html"
}

@test "merge_federation_output: skips failed modules" {
    # Setup: 2 modules, one failed
    export MODULES_COUNT=2
    export MODULE_0_NAME="good-module"
    export MODULE_0_DESTINATION="/"
    export MODULE_1_NAME="bad-module"
    export MODULE_1_DESTINATION="/bad"

    # Only create output for successful module
    local output0="$TEST_TEMP_DIR/module-0-output"
    mkdir -p "$output0"
    echo "good content" > "$output0/index.html"

    # Setup arrays (second module failed)
    export MODULE_OUTPUT_DIRS="$output0 "
    export MODULE_BUILD_STATUS="success build_failed"

    # Create output directory
    mkdir -p "$OUTPUT"

    # Merge should succeed but skip failed module
    run merge_federation_output

    [ "$status" -eq 0 ]
    assert_file_exists "$OUTPUT/index.html"
    # Failed module should not be merged
    [ ! -d "$OUTPUT/bad" ]
}

@test "merge_federation_output: respects module merge strategies" {
    # Setup: 2 modules with different merge strategies
    export MODULES_COUNT=2
    export MODULE_0_NAME="module-a"
    export MODULE_0_DESTINATION="/"
    export MODULE_0_MERGE_STRATEGY="overwrite"
    export MODULE_1_NAME="module-b"
    export MODULE_1_DESTINATION="/"
    export MODULE_1_MERGE_STRATEGY="preserve"

    # Create module outputs
    local output0="$TEST_TEMP_DIR/module-0-output"
    local output1="$TEST_TEMP_DIR/module-1-output"

    mkdir -p "$output0" "$output1"
    echo "from module-a" > "$output0/shared.html"
    echo "from module-a only" > "$output0/a-only.html"
    echo "from module-b" > "$output1/shared.html"
    echo "from module-b only" > "$output1/b-only.html"

    # Setup arrays
    export MODULE_OUTPUT_DIRS="$output0 $output1"
    export MODULE_BUILD_STATUS="success success"

    # Create output directory
    mkdir -p "$OUTPUT"

    # Merge
    merge_federation_output

    # Both unique files should exist
    assert_file_exists "$OUTPUT/a-only.html"
    assert_file_exists "$OUTPUT/b-only.html"
    # Shared file exists (with content from first module due to overwrite, then preserved)
    assert_file_exists "$OUTPUT/shared.html"
}
