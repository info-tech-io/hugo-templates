#!/usr/bin/env bash
#
# CSS Path Rewriting Test Suite
# Tests for Child Issue #18 - Stage 2: Path Rewriting Implementation
#

set -euo pipefail
shopt -s globstar nullglob

# Simple rewrite function for testing (mirrors federated-build.sh logic)
rewrite_paths() {
    local file="$1"
    local prefix="$2"

    # Rewrite href="/..." to href="/prefix/..."
    sed -i -E "s|href=\"/([^/\"][^\"]*)\"|href=\"${prefix}/\1\"|g" "$file"

    # Rewrite src="/..." to src="/prefix/..."
    sed -i -E "s|src=\"/([^/\"][^\"]*)\"|src=\"${prefix}/\1\"|g" "$file"

    # Rewrite CSS url(/...) to url(/prefix/...)
    sed -i -E "s|url\\(/([^/)][^\\)]*)\\)|url(${prefix}/\1)|g" "$file"
}

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

cleanup() {
    rm -rf /tmp/test-rewrite-* 2>/dev/null || true
}

trap cleanup EXIT

echo "═══════════════════════════════════════════════════════════"
echo "  CSS Path Rewriting Test Suite"
echo "═══════════════════════════════════════════════════════════"
echo ""

# TEST 1: CSS links
echo "Test 1: Rewrite CSS links"
test_file="/tmp/test-rewrite-1.html"
cat > "$test_file" <<'EOF'
<link href="/css/style.css">
EOF
rewrite_paths "$test_file" "/quiz"
if grep -q 'href="/quiz/css/style.css"' "$test_file"; then
    pass "CSS links"
else
    fail "CSS links"
fi
echo ""

# TEST 2: JS scripts
echo "Test 2: Rewrite JS scripts"
test_file="/tmp/test-rewrite-2.html"
cat > "$test_file" <<'EOF'
<script src="/js/main.js"></script>
EOF
rewrite_paths "$test_file" "/docs"
if grep -q 'src="/docs/js/main.js"' "$test_file"; then
    pass "JS scripts"
else
    fail "JS scripts"
fi
echo ""

# TEST 3: External URLs preserved
echo "Test 3: Preserve external URLs"
test_file="/tmp/test-rewrite-3.html"
cat > "$test_file" <<'EOF'
<link href="https://cdn.com/style.css">
<link href="/local/style.css">
EOF
rewrite_paths "$test_file" "/prefix"
if grep -q 'href="https://cdn.com/style.css"' "$test_file" && \
   grep -q 'href="/prefix/local/style.css"' "$test_file"; then
    pass "External URLs preserved"
else
    fail "External URLs"
fi
echo ""

# TEST 4: Inline CSS
echo "Test 4: Inline CSS url()"
test_file="/tmp/test-rewrite-4.html"
cat > "$test_file" <<'EOF'
<div style="background: url(/images/bg.png)">
EOF
rewrite_paths "$test_file" "/app"
if grep -q 'url(/app/images/bg.png)' "$test_file"; then
    pass "Inline CSS url()"
else
    fail "Inline CSS url()"
fi
echo ""

# TEST 5: Multi-level prefixes
echo "Test 5: Multi-level path prefixes"
test_file="/tmp/test-rewrite-5.html"
cat > "$test_file" <<'EOF'
<link href="/css/style.css">
EOF
rewrite_paths "$test_file" "/docs/product"
if grep -q 'href="/docs/product/css/style.css"' "$test_file"; then
    pass "Multi-level prefixes"
else
    fail "Multi-level prefixes"
fi
echo ""

# Summary
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
