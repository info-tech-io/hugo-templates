#!/usr/bin/env bash
# tests/test-intelligent-merge.sh
# Test suite for intelligent merging system
# Part of Child Issue #19 - Download-Merge-Deploy Logic, Stage 2

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source the federated-build.sh to test its functions
source "$PROJECT_ROOT/scripts/federated-build.sh" >/dev/null 2>&1 || {
    echo "Error: Cannot source federated-build.sh"
    exit 1
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
print_test_header() {
    echo ""
    echo "========================================="
    echo "$1"
    echo "========================================="
}

pass_test() {
    echo "✓ $1"
    ((TESTS_PASSED++))
}

fail_test() {
    echo "✗ $1"
    ((TESTS_FAILED++))
}

# ===========================================================================
# Test 1: Conflict detection accuracy
# ===========================================================================
test_conflict_detection() {
    print_test_header "Test 1: Conflict Detection Accuracy"

    local existing_dir="/tmp/test-existing-$$"
    local new_dir="/tmp/test-new-$$"

    mkdir -p "$existing_dir" "$new_dir"

    # Create conflicting file
    echo "existing content" > "$existing_dir/conflict.html"
    echo "new content" > "$new_dir/conflict.html"

    # Create non-conflicting file
    echo "unique" > "$new_dir/unique.html"

    declare -a conflicts=()
    detect_merge_conflicts "$existing_dir" "$new_dir" conflicts >/dev/null 2>&1

    if [[ ${#conflicts[@]} -eq 1 ]] && [[ "${conflicts[0]}" == "conflict.html" ]]; then
        pass_test "Conflict detected correctly (1 conflict found)"
        rm -rf "$existing_dir" "$new_dir"
        return 0
    else
        fail_test "Expected 1 conflict, found ${#conflicts[@]}"
        rm -rf "$existing_dir" "$new_dir"
        return 1
    fi
}

# ===========================================================================
# Test 2: Overwrite strategy
# ===========================================================================
test_overwrite_strategy() {
    print_test_header "Test 2: Overwrite Strategy"

    local source="/tmp/test-source-$$"
    local target="/tmp/test-target-$$"

    mkdir -p "$source" "$target"
    echo "old content" > "$target/file.html"
    echo "new content" > "$source/file.html"

    merge_with_strategy "$source" "$target" "overwrite" >/dev/null 2>&1

    local content
    content=$(cat "$target/file.html")

    if [[ "$content" == "new content" ]]; then
        pass_test "Overwrite strategy replaced old content with new"
        rm -rf "$source" "$target"
        return 0
    else
        fail_test "Overwrite failed: expected 'new content', got '$content'"
        rm -rf "$source" "$target"
        return 1
    fi
}

# ===========================================================================
# Test 3: Preserve strategy
# ===========================================================================
test_preserve_strategy() {
    print_test_header "Test 3: Preserve Strategy"

    local source="/tmp/test-source-$$"
    local target="/tmp/test-target-$$"

    mkdir -p "$source" "$target"
    echo "old content" > "$target/file.html"
    echo "new content" > "$source/file.html"
    echo "unique" > "$source/unique.html"

    merge_with_strategy "$source" "$target" "preserve" >/dev/null 2>&1

    local existing_content
    local unique_content
    existing_content=$(cat "$target/file.html")
    unique_content=$(cat "$target/unique.html" 2>/dev/null || echo "missing")

    if [[ "$existing_content" == "old content" ]] && [[ "$unique_content" == "unique" ]]; then
        pass_test "Preserve strategy kept existing file and added unique file"
        rm -rf "$source" "$target"
        return 0
    else
        fail_test "Preserve failed: existing='$existing_content', unique='$unique_content'"
        rm -rf "$source" "$target"
        return 1
    fi
}

# ===========================================================================
# Test 4: Error strategy with conflicts
# ===========================================================================
test_error_strategy() {
    print_test_header "Test 4: Error Strategy with Conflicts"

    local source="/tmp/test-source-$$"
    local target="/tmp/test-target-$$"

    mkdir -p "$source" "$target"
    echo "old content" > "$target/file.html"
    echo "new content" > "$source/file.html"

    if ! merge_with_strategy "$source" "$target" "error" >/dev/null 2>&1; then
        pass_test "Error strategy rejected conflict as expected"
        rm -rf "$source" "$target"
        return 0
    else
        fail_test "Error strategy should have failed on conflict"
        rm -rf "$source" "$target"
        return 1
    fi
}

# ===========================================================================
# Test 5: Error strategy without conflicts
# ===========================================================================
test_error_strategy_no_conflict() {
    print_test_header "Test 5: Error Strategy without Conflicts"

    local source="/tmp/test-source-$$"
    local target="/tmp/test-target-$$"

    mkdir -p "$source" "$target"
    echo "new content" > "$source/unique.html"

    if merge_with_strategy "$source" "$target" "error" >/dev/null 2>&1; then
        local content
        content=$(cat "$target/unique.html")

        if [[ "$content" == "new content" ]]; then
            pass_test "Error strategy merged successfully when no conflicts"
            rm -rf "$source" "$target"
            return 0
        else
            fail_test "File content incorrect: '$content'"
            rm -rf "$source" "$target"
            return 1
        fi
    else
        fail_test "Error strategy should succeed when no conflicts"
        rm -rf "$source" "$target"
        return 1
    fi
}

# ===========================================================================
# Test 6: Merge strategy (basic)
# ===========================================================================
test_merge_strategy() {
    print_test_header "Test 6: Merge Strategy (Basic)"

    local source="/tmp/test-source-$$"
    local target="/tmp/test-target-$$"

    mkdir -p "$source" "$target"
    echo "line 1" > "$target/file.txt"
    echo "line 2" > "$source/file.txt"
    echo "unique" > "$source/unique.html"

    merge_with_strategy "$source" "$target" "merge" >/dev/null 2>&1

    local merged_content
    merged_content=$(cat "$target/file.txt")
    local unique_content
    unique_content=$(cat "$target/unique.html" 2>/dev/null || echo "missing")

    # Merge strategy concatenates text files
    if [[ "$merged_content" == *"line 1"* ]] && [[ "$merged_content" == *"line 2"* ]]; then
        pass_test "Merge strategy combined text file content"
        rm -rf "$source" "$target"
        return 0
    else
        fail_test "Merge strategy failed to combine content: '$merged_content'"
        rm -rf "$source" "$target"
        return 1
    fi
}

# ===========================================================================
# Run all tests
# ===========================================================================
main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║   Intelligent Merge Tests - Stage 2                 ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""

    # Run tests
    test_conflict_detection
    test_overwrite_strategy
    test_preserve_strategy
    test_error_strategy
    test_error_strategy_no_conflict
    test_merge_strategy

    # Print summary
    echo ""
    echo "========================================="
    echo "Test Summary"
    echo "========================================="
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "✓ All tests passed!"
        return 0
    else
        echo "✗ Some tests failed"
        return 1
    fi
}

# Execute main function
main "$@"
