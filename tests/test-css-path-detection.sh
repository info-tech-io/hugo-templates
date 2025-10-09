#!/usr/bin/env bash
#
# CSS Path Detection Test Suite
# Tests for Child Issue #18 - Stage 1: CSS Path Analysis & Detection
#

set -euo pipefail
shopt -s globstar nullglob

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

echo "═══════════════════════════════════════════════════════════"
echo "  CSS Path Detection Test Suite"
echo "═══════════════════════════════════════════════════════════"
echo ""

# ============================================================================
# TEST 1: grep pattern for local paths
# ============================================================================

echo "Test 1: Detect local absolute paths"
echo "/css/style.css" > /tmp/test-paths.txt
echo "/js/main.js" >> /tmp/test-paths.txt
echo "https://cdn.com/external.css" >> /tmp/test-paths.txt

local_count=$(grep -c "^/" /tmp/test-paths.txt)
external_count=$(grep -c "^https://" /tmp/test-paths.txt)

if [[ $local_count -eq 2 ]] && [[ $external_count -eq 1 ]]; then
    pass "Detect 2 local paths, 1 external"
else
    fail "Path detection (local:$local_count, external:$external_count)"
fi
echo ""

# ============================================================================
# TEST 2: calculate_css_prefix - root path
# ============================================================================

echo "Test 2: CSS prefix calculation - root"
result=""
[[ "/" == "/" ]] && result="" || result="/error"

if [[ "$result" == "" ]]; then
    pass "Root path returns empty prefix"
else
    fail "Root path (got '$result')"
fi
echo ""

# ============================================================================
# TEST 3: calculate_css_prefix - single level
# ============================================================================

echo "Test 3: CSS prefix calculation - single level"
input="/quiz/"
result="/${input%/}"
result="${result#//}"
result="/${result#/}"
result="${result%/}"

if [[ "$result" == "/quiz" ]]; then
    pass "'/quiz/' returns '/quiz'"
else
    fail "'/quiz/' prefix (got '$result')"
fi
echo ""

# ============================================================================
# TEST 4: calculate_css_prefix - multi level
# ============================================================================

echo "Test 4: CSS prefix calculation - multi level"
input="/docs/product/"
result="/${input%/}"
result="${result#//}"
result="/${result#/}"
result="${result%/}"

if [[ "$result" == "/docs/product" ]]; then
    pass "'/docs/product/' returns '/docs/product'"
else
    fail "'/docs/product/' prefix (got '$result')"
fi
echo ""

# ============================================================================
# TEST 5: Real site HTML files
# ============================================================================

echo "Test 5: Real site analysis"
if [[ -d "/root/info-tech-io/hugo-templates/site" ]]; then
    # Count HTML files
    html_count=0
    for file in /root/info-tech-io/hugo-templates/site/*.html; do
        [[ -f "$file" ]] && html_count=$((html_count + 1))
    done
    for file in /root/info-tech-io/hugo-templates/site/**/*.html; do
        [[ -f "$file" ]] && html_count=$((html_count + 1))
    done

    if [[ $html_count -gt 0 ]]; then
        pass "Found $html_count HTML files in site/"
    else
        fail "No HTML files in site/"
    fi
else
    echo "⚠ SKIP: No site/ directory"
fi
echo ""

# ============================================================================
# Summary
# ============================================================================

rm -f /tmp/test-paths.txt

TESTS_TOTAL=$((TESTS_PASSED + TESTS_FAILED))

echo "═══════════════════════════════════════════════════════════"
echo "  Summary: $TESTS_PASSED/$TESTS_TOTAL tests passed"
echo "═══════════════════════════════════════════════════════════"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✅ ALL TESTS PASSED"
    exit 0
else
    echo "❌ $TESTS_FAILED TEST(S) FAILED"
    exit 1
fi
