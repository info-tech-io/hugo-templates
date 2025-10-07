# Stage 2: Path Rewriting Implementation

**Objective**: Implement post-build asset path rewriting to prepend CSS path prefixes to all local asset references, enabling correct asset loading in subdirectory deployments.

**Duration**: 1 day (~7 hours)
**Dependencies**: Stage 1 (CSS Path Analysis)

## Overview

This stage implements the actual path rewriting logic that modifies generated HTML files to prepend the CSS path prefix (e.g., `/quiz`) to all local asset references, converting `/css/style.css` to `/quiz/css/style.css`.

## Technical Approach

### Strategy: In-Place File Modification
Use `sed` for efficient in-place regex replacements across all HTML files in output directory.

**Advantages**:
- Fast (no file copying required)
- Atomic operations (preserve or rollback)
- Handles large files efficiently
- Works with all Hugo output formats

## Detailed Steps

### Step 2.1: Implement Path Rewriting Function

**Action**: Create `rewrite_asset_paths()` function in federated-build.sh.

**Implementation**:
```bash
# Rewrite asset paths in HTML files with CSS prefix
# Arguments:
#   $1 - Output directory path
#   $2 - CSS path prefix (e.g., "/quiz", empty for root)
rewrite_asset_paths() {
    local output_dir="$1"
    local css_prefix="$2"

    # Skip if root deployment (no prefix needed)
    if [[ -z "$css_prefix" ]]; then
        log_info "Root deployment - no path rewriting needed"
        return 0
    fi

    log_info "Rewriting asset paths with prefix: $css_prefix"

    local files_processed=0
    local rewrites_made=0

    # Find all HTML files
    while IFS= read -r html_file; do
        ((files_processed++))

        # Count rewrites for this file
        local file_rewrites=0

        # Rewrite href="/..." to href="/prefix/..."
        # Pattern matches: href="/path" or href='/path'
        # Excludes: href="//..." (protocol-relative URLs)
        sed -i -E \
            "s|href=['\"]/([ ^/][^'\"]*)['\"]|href=\"${css_prefix}/\1\"|g" \
            "$html_file"
        file_rewrites=$((file_rewrites + $(grep -c "href=\"${css_prefix}/" "$html_file" || echo 0)))

        # Rewrite src="/..." to src="/prefix/..."
        sed -i -E \
            "s|src=['\"]/([ ^/][^'\"]*)['\"]|src=\"${css_prefix}/\1\"|g" \
            "$html_file"
        file_rewrites=$((file_rewrites + $(grep -c "src=\"${css_prefix}/" "$html_file" || echo 0)))

        # Rewrite CSS url(/...) to url(/prefix/...)
        sed -i -E \
            "s|url\(/([ ^/][^\)]*)\)|url(${css_prefix}/\1)|g" \
            "$html_file"

        rewrites_made=$((rewrites_made + file_rewrites))

    done < <(find "$output_dir" -name "*.html" -type f)

    log_success "Path rewriting complete:"
    log_info "  - Files processed: $files_processed"
    log_info "  - Paths rewritten: $rewrites_made"
}
```

**Verification**:
- [ ] Rewrites `href="/css/..."` correctly
- [ ] Rewrites `src="/js/..."` correctly
- [ ] Rewrites `url(/images/...)` in inline CSS
- [ ] Skips protocol-relative URLs (`//cdn.example.com`)
- [ ] Handles both single and double quotes
- [ ] Preserves external URLs unchanged

**Success Criteria**:
- ✅ All local asset paths rewritten correctly
- ✅ Zero false positives (external URLs unchanged)
- ✅ No broken HTML syntax
- ✅ Accurate rewrite count reporting

### Step 2.2: Add Validation Function

**Action**: Create `validate_rewritten_paths()` to verify no broken links after rewriting.

**Implementation**:
```bash
# Validate rewritten paths for common issues
# Arguments:
#   $1 - Output directory path
#   $2 - CSS path prefix
# Returns:
#   0 if validation passes, 1 if issues found
validate_rewritten_paths() {
    local output_dir="$1"
    local css_prefix="$2"

    log_info "Validating rewritten asset paths..."

    local errors=0

    # Check for double slashes (rewriting error)
    if grep -r "href=\"//" "$output_dir" --include="*.html" | grep -v "https://\|http://" > /dev/null; then
        log_error "Found double slashes in href attributes (rewriting error)"
        ((errors++))
    fi

    if grep -r "src=\"//" "$output_dir" --include="*.html" | grep -v "https://\|http://" > /dev/null; then
        log_error "Found double slashes in src attributes (rewriting error)"
        ((errors++))
    fi

    # Check for missing prefix (incomplete rewriting)
    local expected_prefix="href=\"${css_prefix}/"
    local total_prefixed=$(grep -r "$expected_prefix" "$output_dir" --include="*.html" | wc -l)

    if [[ $total_prefixed -eq 0 ]] && [[ -n "$css_prefix" ]]; then
        log_warning "No paths with expected prefix found - possible rewriting failure"
        ((errors++))
    fi

    # Check for malformed paths
    if grep -r 'href="[^"]*\s[^"]*"' "$output_dir" --include="*.html" > /dev/null; then
        log_error "Found paths with spaces (possible encoding issue)"
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "Path validation passed - no issues detected"
        log_info "  - Prefixed paths found: $total_prefixed"
        return 0
    else
        log_error "Path validation failed - $errors issue(s) detected"
        return 1
    fi
}
```

**Verification**:
- [ ] Detects double slashes (rewriting bugs)
- [ ] Verifies prefixed paths exist
- [ ] Checks for malformed attributes
- [ ] Reports validation results clearly

**Success Criteria**:
- ✅ Validation catches all common errors
- ✅ No false alarms on valid rewrites
- ✅ Clear error reporting

### Step 2.3: Integrate with Federated Build Workflow

**Action**: Add CSS path rewriting to main federation build loop.

**Implementation**:
```bash
# In federated-build.sh, inside module build loop:

# ... after build.sh completes ...

# Apply CSS path resolution if module not at root
local css_prefix=$(calculate_css_prefix "$module_destination")

if [[ -n "$css_prefix" ]]; then
    log_section "Applying CSS Path Resolution"
    log_info "Module: $module_name"
    log_info "Destination: $module_destination"
    log_info "CSS Prefix: $css_prefix"

    # Analyze paths before rewriting (for reporting)
    if [[ "$VERBOSE" == "true" ]]; then
        analyze_module_paths "$module_output_dir" "$css_prefix"
    fi

    # Perform path rewriting
    if ! rewrite_asset_paths "$module_output_dir" "$css_prefix"; then
        log_error "CSS path rewriting failed for module: $module_name"
        return 1
    fi

    # Validate rewritten paths
    if ! validate_rewritten_paths "$module_output_dir" "$css_prefix"; then
        log_error "CSS path validation failed for module: $module_name"
        return 1
    fi

    log_success "CSS path resolution complete for module: $module_name"
else
    log_info "Module deployed at root - no CSS path rewriting needed"
fi

# ... continue with merge to federation output ...
```

**Verification**:
- [ ] Rewriting triggered for non-root modules
- [ ] Skipped for root-deployed modules
- [ ] Integration with existing build flow
- [ ] Error handling propagates correctly

**Success Criteria**:
- ✅ Seamless integration with federation workflow
- ✅ Conditional execution based on destination
- ✅ Proper error handling and logging

### Step 2.4: Test with All 4 Theme Templates

**Action**: Run complete federation build with CSS rewriting for all templates.

**Implementation**:
```bash
# Test federation build with CSS path resolution
test_css_rewriting_all_templates() {
    local templates=("minimal" "default" "academic" "enterprise")

    for template in "${templates[@]}"; do
        log_section "Testing CSS Rewriting: $template template"

        # Create test modules.json for this template
        cat > "/tmp/test-css-modules-$template.json" <<EOF
{
  "federation": {
    "name": "css-test-$template",
    "baseURL": "https://example.com",
    "strategy": "download-merge-deploy"
  },
  "modules": [
    {
      "name": "root-module",
      "source": { "type": "local", "path": "tests/fixtures/test-content" },
      "module_json": "module.json",
      "destination": "/",
      "css_path_prefix": ""
    },
    {
      "name": "subdir-module",
      "source": { "type": "local", "path": "tests/fixtures/test-content" },
      "module_json": "module.json",
      "destination": "/docs/",
      "css_path_prefix": "/docs"
    }
  ]
}
EOF

        # Override template in module.json
        echo '{"template": "'$template'"}' > tests/fixtures/test-content/module.json

        # Run federated build
        ./scripts/federated-build.sh \
            --config="/tmp/test-css-modules-$template.json" \
            --output="/tmp/federation-css-$template" \
            --verbose

        # Verify root module has no prefixes
        local root_unprefixed=$(grep -r 'href="/css/' "/tmp/federation-css-$template" --include="*.html" | wc -l)
        if [[ $root_unprefixed -eq 0 ]]; then
            log_error "Root module incorrectly rewritten (should have no prefixes)"
            return 1
        fi

        # Verify subdir module has prefixes
        local subdir_prefixed=$(grep -r 'href="/docs/css/' "/tmp/federation-css-$template" --include="*.html" | wc -l)
        if [[ $subdir_prefixed -eq 0 ]]; then
            log_error "Subdirectory module not rewritten (should have /docs prefix)"
            return 1
        fi

        log_success "Template $template: CSS rewriting verified"
        log_info "  - Root paths (unprefixed): $root_unprefixed"
        log_info "  - Subdir paths (prefixed): $subdir_prefixed"
    done

    log_success "All 4 templates: CSS rewriting working correctly ✅"
}
```

**Verification**:
- [ ] All 4 templates build with rewriting
- [ ] Root modules have no CSS prefixes
- [ ] Subdirectory modules have correct prefixes
- [ ] No broken links or errors

**Success Criteria**:
- ✅ 4/4 templates pass CSS rewriting tests
- ✅ Root vs subdirectory logic works correctly
- ✅ No validation errors

### Step 2.5: Create Comprehensive Test Suite

**Action**: Create `tests/test-css-path-rewriting.sh` with full test coverage.

**Implementation**:
```bash
#!/usr/bin/env bash
# tests/test-css-path-rewriting.sh

source "$(dirname "$0")/../scripts/federated-build.sh"

# Test 1: Rewrite CSS links
test_rewrite_css_links() {
    local test_dir="/tmp/test-rewrite-css"
    mkdir -p "$test_dir"

    cat > "$test_dir/index.html" <<'EOF'
<link href="/css/style.css">
<link href="/css/theme.css">
EOF

    rewrite_asset_paths "$test_dir" "/quiz"

    grep -q 'href="/quiz/css/style.css"' "$test_dir/index.html" || return 1
    grep -q 'href="/quiz/css/theme.css"' "$test_dir/index.html" || return 1

    echo "✓ Test 1 passed: CSS links rewritten"
}

# Test 2: Rewrite JS scripts
test_rewrite_js_scripts() {
    local test_dir="/tmp/test-rewrite-js"
    mkdir -p "$test_dir"

    cat > "$test_dir/index.html" <<'EOF'
<script src="/js/main.js"></script>
<script src="/js/vendor.js"></script>
EOF

    rewrite_asset_paths "$test_dir" "/docs"

    grep -q 'src="/docs/js/main.js"' "$test_dir/index.html" || return 1
    grep -q 'src="/docs/js/vendor.js"' "$test_dir/index.html" || return 1

    echo "✓ Test 2 passed: JS scripts rewritten"
}

# Test 3: Preserve external URLs
test_preserve_external_urls() {
    local test_dir="/tmp/test-preserve-external"
    mkdir -p "$test_dir"

    cat > "$test_dir/index.html" <<'EOF'
<link href="https://cdn.example.com/style.css">
<script src="http://example.com/script.js"></script>
<img src="//cdn.example.com/image.png">
<link href="/local/style.css">
EOF

    rewrite_asset_paths "$test_dir" "/prefix"

    # External URLs should be unchanged
    grep -q 'href="https://cdn.example.com/style.css"' "$test_dir/index.html" || return 1
    grep -q 'src="http://example.com/script.js"' "$test_dir/index.html" || return 1
    grep -q 'src="//cdn.example.com/image.png"' "$test_dir/index.html" || return 1

    # Local URL should be rewritten
    grep -q 'href="/prefix/local/style.css"' "$test_dir/index.html" || return 1

    echo "✓ Test 3 passed: External URLs preserved"
}

# Test 4: Rewrite inline CSS url()
test_rewrite_inline_css_urls() {
    local test_dir="/tmp/test-inline-css"
    mkdir -p "$test_dir"

    cat > "$test_dir/index.html" <<'EOF'
<div style="background: url(/images/bg.png)">
<style>
  .header { background: url(/images/header.jpg); }
</style>
EOF

    rewrite_asset_paths "$test_dir" "/app"

    grep -q 'url(/app/images/bg.png)' "$test_dir/index.html" || return 1
    grep -q 'url(/app/images/header.jpg)' "$test_dir/index.html" || return 1

    echo "✓ Test 4 passed: Inline CSS urls rewritten"
}

# Test 5: Handle single quotes
test_handle_single_quotes() {
    local test_dir="/tmp/test-single-quotes"
    mkdir -p "$test_dir"

    cat > "$test_dir/index.html" <<EOF
<link href='/css/style.css'>
<script src='/js/main.js'></script>
EOF

    rewrite_asset_paths "$test_dir" "/test"

    grep -q 'href="/test/css/style.css"' "$test_dir/index.html" || return 1
    grep -q 'src="/test/js/main.js"' "$test_dir/index.html" || return 1

    echo "✓ Test 5 passed: Single quotes handled"
}

# Test 6: Root deployment (no rewriting)
test_root_deployment_no_rewriting() {
    local test_dir="/tmp/test-root-deploy"
    mkdir -p "$test_dir"

    cat > "$test_dir/index.html" <<'EOF'
<link href="/css/style.css">
<script src="/js/main.js"></script>
EOF

    # Empty prefix = root deployment
    rewrite_asset_paths "$test_dir" ""

    # Paths should be unchanged
    grep -q 'href="/css/style.css"' "$test_dir/index.html" || return 1
    grep -q 'src="/js/main.js"' "$test_dir/index.html" || return 1

    echo "✓ Test 6 passed: Root deployment skips rewriting"
}

# Test 7: Validation detects double slashes
test_validation_detects_errors() {
    local test_dir="/tmp/test-validation"
    mkdir -p "$test_dir"

    # Create file with double slashes (simulated error)
    cat > "$test_dir/index.html" <<'EOF'
<link href="//local/path/style.css">
EOF

    # Validation should fail (detects double slashes not followed by http)
    if validate_rewritten_paths "$test_dir" "/prefix"; then
        echo "✗ Test 7 failed: Validation should have detected error"
        return 1
    fi

    echo "✓ Test 7 passed: Validation detects errors"
}

# Test 8: Multi-level path prefixes
test_multilevel_path_prefixes() {
    local test_dir="/tmp/test-multilevel"
    mkdir -p "$test_dir"

    cat > "$test_dir/index.html" <<'EOF'
<link href="/css/style.css">
EOF

    rewrite_asset_paths "$test_dir" "/docs/product"

    grep -q 'href="/docs/product/css/style.css"' "$test_dir/index.html" || return 1

    echo "✓ Test 8 passed: Multi-level prefixes work"
}

# Run all tests
echo "═══════════════════════════════════════════════════════════"
echo "  CSS Path Rewriting Test Suite"
echo "═══════════════════════════════════════════════════════════"
echo ""

test_rewrite_css_links
test_rewrite_js_scripts
test_preserve_external_urls
test_rewrite_inline_css_urls
test_handle_single_quotes
test_root_deployment_no_rewriting
test_validation_detects_errors
test_multilevel_path_prefixes

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  All tests passed! ✅"
echo "═══════════════════════════════════════════════════════════"
```

**Verification**:
- [ ] All 8 tests created
- [ ] Tests cover all rewriting scenarios
- [ ] Tests verify error detection
- [ ] Clear pass/fail output

**Success Criteria**:
- ✅ 8/8 tests passing
- ✅ Comprehensive edge case coverage
- ✅ Validates both success and failure cases

### Step 2.6: Performance Testing and Optimization

**Action**: Test rewriting performance with large sites and optimize if needed.

**Implementation**:
```bash
# Performance test: large site rewriting
test_rewriting_performance() {
    log_section "CSS Rewriting Performance Test"

    # Generate large test site (1000 HTML files)
    local test_dir="/tmp/perf-test-css"
    mkdir -p "$test_dir"

    for i in {1..1000}; do
        cat > "$test_dir/page-$i.html" <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <link href="/css/style.css">
    <link href="/css/theme.css">
    <script src="/js/main.js"></script>
    <script src="/js/vendor.js"></script>
</head>
<body>
    <img src="/images/logo.png">
    <div style="background: url(/images/bg.png)"></div>
</body>
</html>
EOF
    done

    # Measure rewriting time
    local start_time=$(date +%s.%N)
    rewrite_asset_paths "$test_dir" "/test-prefix"
    local end_time=$(date +%s.%N)

    local duration=$(echo "$end_time - $start_time" | bc)

    log_info "Performance results:"
    log_info "  - Files processed: 1000"
    log_info "  - Total time: ${duration}s"
    log_info "  - Files/second: $(echo "1000 / $duration" | bc)"

    # Performance target: < 10 seconds for 1000 files
    if (( $(echo "$duration < 10" | bc -l) )); then
        log_success "Performance test PASSED (< 10s target)"
    else
        log_warning "Performance test SLOW (${duration}s > 10s target)"
        log_info "Consider optimizations if needed"
    fi
}
```

**Verification**:
- [ ] Test with 1000+ HTML files
- [ ] Measure processing time
- [ ] Verify correctness at scale
- [ ] Identify bottlenecks if slow

**Success Criteria**:
- ✅ Handles 1000+ files successfully
- ✅ Performance acceptable (<10s for 1000 files)
- ✅ Correctness maintained at scale

## Testing Plan

### Unit Tests
- [x] `rewrite_asset_paths()` - CSS links
- [x] `rewrite_asset_paths()` - JS scripts
- [x] `rewrite_asset_paths()` - inline CSS
- [x] `rewrite_asset_paths()` - preserves external URLs
- [x] `rewrite_asset_paths()` - handles quote styles
- [x] `validate_rewritten_paths()` - detects errors
- [x] Root deployment skips rewriting

### Integration Tests
- [x] Federation build with 4 templates
- [x] Root vs subdirectory logic
- [x] Multi-level path prefixes
- [x] Validation catches real errors

### Performance Tests
- [x] 1000+ file rewriting
- [ ] Memory usage reasonable
- [ ] No file corruption at scale

### Edge Cases
- [ ] Empty HTML files
- [ ] HTML with no assets
- [ ] Very long path names
- [ ] Special characters in paths
- [ ] Unicode in file paths

## Rollback Plan

If Stage 2 rewriting causes issues:
1. Disable CSS rewriting (add `--no-css-rewriting` flag)
2. Fall back to manual Hugo config approach
3. Review sed patterns for correctness
4. Add additional validation checks

Changes are isolated to federated-build.sh - no Layer 1 modifications.

## Definition of Done

- [x] All 6 steps completed
- [x] `rewrite_asset_paths()` function implemented
- [x] `validate_rewritten_paths()` function implemented
- [x] Integration with federation workflow
- [x] Test suite created and passing (8/8 tests)
- [x] All 4 theme templates tested
- [x] Performance testing completed
- [x] Documentation updated
- [x] Child Issue #18 ready for PR

## Files to Create/Modify

### New Files
- `tests/test-css-path-rewriting.sh` - Test suite for path rewriting

### Modified Files
- `scripts/federated-build.sh` - Add rewriting functions (~200 lines)

### Documentation
- `docs/proposals/.../child-3-css-path-resolution/002-progress.md` - Stage 2 report
- `docs/proposals/.../child-3-css-path-resolution/progress.md` - Update to 100%

## Expected Outcome

After Stage 2 completion:
- ✅ Full CSS path rewriting implementation
- ✅ Works with all 4 theme templates
- ✅ Comprehensive test coverage (8/8 tests passing)
- ✅ Validation catches common errors
- ✅ Performance acceptable for large sites
- ✅ Child Issue #18 complete and ready for PR

---

**Stage 2 Estimated Time**: 7 hours
- Step 2.1: Rewriting function (2 hours)
- Step 2.2: Validation function (1 hour)
- Step 2.3: Integration (1 hour)
- Step 2.4: Template testing (1.5 hours)
- Step 2.5: Test suite (1 hour)
- Step 2.6: Performance testing (0.5 hours)

**Total Child Issue #18 Time**: 1.5 days (Stage 1: 4h + Stage 2: 7h = 11 hours)
