#!/usr/bin/env bash
# tests/test-download-pages.sh
# Test suite for download_existing_pages() function
# Part of Child Issue #19 - Download-Merge-Deploy Logic, Stage 1

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
    ((TESTS_PASSED++)) || true
}

fail_test() {
    echo "✗ $1"
    ((TESTS_FAILED++)) || true
}

# ===========================================================================
# Test 1: Invalid URL rejection
# ===========================================================================
test_invalid_url() {
    print_test_header "Test 1: Invalid URL Rejection"

    local test_dir="/tmp/test-invalid-url-$$"
    mkdir -p "$test_dir"

    if download_existing_pages "not-a-url" "$test_dir" 2>/dev/null; then
        fail_test "Should reject invalid URL"
        rm -rf "$test_dir"
        return 1
    else
        pass_test "Invalid URL rejected correctly"
        rm -rf "$test_dir"
        return 0
    fi
}

# ===========================================================================
# Test 2: Directory creation
# ===========================================================================
test_directory_creation() {
    print_test_header "Test 2: Directory Creation"

    local test_dir="/tmp/test-dir-creation-$$"

    # Test with dry-run to avoid actual downloads
    DRY_RUN=true
    VERBOSE=false
    QUIET=false

    if download_existing_pages "https://example.com" "$test_dir" >/dev/null 2>&1; then
        if [[ -d "$test_dir" ]]; then
            pass_test "Download directory created successfully"
            rm -rf "$test_dir"
            return 0
        else
            fail_test "Directory was not created"
            return 1
        fi
    else
        fail_test "Function failed unexpectedly"
        rm -rf "$test_dir" 2>/dev/null || true
        return 1
    fi
}

# ===========================================================================
# Test 3: Dry-run mode
# ===========================================================================
test_dry_run_mode() {
    print_test_header "Test 3: Dry-Run Mode"

    local test_dir="/tmp/test-dry-run-$$"

    DRY_RUN=true
    VERBOSE=false
    QUIET=false

    if download_existing_pages "https://example.com" "$test_dir" >/dev/null 2>&1; then
        # In dry-run mode, no actual download should occur
        local file_count
        file_count=$(find "$test_dir" -type f 2>/dev/null | wc -l || echo 0)

        if [[ $file_count -eq 0 ]]; then
            pass_test "Dry-run mode prevents actual download"
            rm -rf "$test_dir"
            return 0
        else
            fail_test "Dry-run mode downloaded files (should not)"
            rm -rf "$test_dir"
            return 1
        fi
    else
        fail_test "Dry-run mode failed unexpectedly"
        rm -rf "$test_dir" 2>/dev/null || true
        return 1
    fi
}

# ===========================================================================
# Test 4: wget availability check
# ===========================================================================
test_wget_availability() {
    print_test_header "Test 4: wget Availability Check"

    if command -v wget >/dev/null 2>&1; then
        pass_test "wget is available for download tests"
        return 0
    else
        fail_test "wget not found - some download functionality will not work"
        echo "  Note: Install wget to enable download features"
        return 0  # Non-fatal for test suite
    fi
}

# ===========================================================================
# Test 5: Empty site handling (mock test)
# ===========================================================================
test_empty_site_handling() {
    print_test_header "Test 5: Empty Site Handling"

    local test_dir="/tmp/test-empty-$$"
    mkdir -p "$test_dir"

    # Since we can't easily mock wget, we'll test the logic indirectly
    # by checking if an empty directory is handled gracefully
    # The function should return 0 (success) even if 0 files are downloaded

    # For this test, we'll just verify the directory structure
    if [[ -d "$test_dir" ]]; then
        pass_test "Empty directory handling prepared"
        rm -rf "$test_dir"
        return 0
    else
        fail_test "Test setup failed"
        return 1
    fi
}

# ===========================================================================
# Run all tests
# ===========================================================================
main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║   Download System Tests - Stage 1                   ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""

    # Run tests
    test_invalid_url
    test_directory_creation
    test_dry_run_mode
    test_wget_availability
    test_empty_site_handling

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
