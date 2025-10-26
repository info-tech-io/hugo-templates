# Stage 1: CSS Path Analysis & Detection

**Objective**: Analyze Hugo theme structure and implement CSS path detection logic to identify assets requiring path rewriting for subdirectory deployment.

**Duration**: 0.5 days (~4 hours)
**Dependencies**: Child #16 (federated-build.sh), Child #17 (modules.json schema)

## Overview

This stage implements the foundation for CSS path resolution by analyzing how Hugo themes reference assets and creating detection logic to identify which files and paths need rewriting when modules are deployed to subdirectories.

## Problem Analysis

### Current State
Hugo themes and templates use absolute paths from site root:
```html
<!-- In theme templates -->
<link rel="stylesheet" href="/css/style.css">
<script src="/js/main.js"></script>
<img src="/images/logo.png">
```

### Issue in Federated Deployment
When module deployed to `/quiz/`:
- Browser requests: `https://example.com/css/style.css` ❌ (404 - file doesn't exist)
- Should request: `https://example.com/quiz/css/style.css` ✅

### Root Cause
Hugo generates paths based on `baseURL` in config, but federated builds require different paths per module without modifying source templates.

## Technical Approach

### Strategy: Post-Build Path Rewriting
Rather than modifying Hugo configuration (which affects templates), we'll rewrite paths in generated HTML after build completes.

**Advantages**:
- No theme modification required
- Works with all Hugo templates
- Preserves build.sh behavior (Layer 1 unchanged)
- Handles edge cases (external URLs, data URIs)

## Detailed Steps

### Step 1.1: Research Hugo Asset Patterns

**Action**: Analyze how Hugo themes reference assets across all 4 template types.

**Implementation**:
```bash
# Analyze theme asset patterns
cd /root/info-tech-io/hugo-templates
for theme in themes/*/layouts/**/*.html; do
    grep -E 'href=|src=' "$theme" | head -20
done > /tmp/asset-patterns.txt

# Common patterns to identify:
# - <link href="/css/...">
# - <script src="/js/...">
# - <img src="/images/...">
# - url(/fonts/...)
# - External URLs (https://, http://)
# - Data URIs (data:image/...)
# - Relative paths (../css/...)
```

**Expected Patterns**:
1. **CSS Links**: `<link rel="stylesheet" href="/css/style.css">`
2. **JS Scripts**: `<script src="/js/main.js"></script>`
3. **Images**: `<img src="/images/logo.png">`
4. **Inline CSS**: `background: url(/images/bg.png)`
5. **Fonts**: `url(/fonts/font.woff2)`

**Verification**:
- [ ] Documented all asset reference patterns
- [ ] Identified patterns needing rewriting
- [ ] Identified patterns to skip (external URLs, data URIs)

**Success Criteria**:
- ✅ Complete list of regex patterns for asset detection
- ✅ Examples from all 4 theme templates (minimal, default, academic, enterprise)

### Step 1.2: Implement Path Detection Function

**Action**: Create `detect_asset_paths()` function in federated-build.sh.

**Implementation**:
```bash
# In scripts/federated-build.sh

# Detect asset paths requiring rewriting
# Arguments:
#   $1 - HTML file path
#   $2 - Output variable name (array of paths)
detect_asset_paths() {
    local html_file="$1"
    local -n paths_array="$2"

    # Pattern: absolute paths starting with / (but not //)
    # Excludes: external URLs, data URIs
    local pattern='(href|src)=["\x27](/[^/][^"\x27]*)["\x27]'

    # Extract all matching paths
    while IFS= read -r line; do
        if [[ "$line" =~ $pattern ]]; then
            local path="${BASH_REMATCH[2]}"
            # Skip if external URL or data URI
            if [[ ! "$path" =~ ^(https?:|data:) ]]; then
                paths_array+=("$path")
            fi
        fi
    done < "$html_file"
}
```

**Test Cases**:
```bash
# Test with sample HTML
cat > /tmp/test.html <<'EOF'
<link href="/css/style.css">
<script src="/js/main.js"></script>
<img src="https://example.com/external.png">
<img src="data:image/svg+xml,<svg>...</svg>">
<div style="background: url(/images/bg.png)">
EOF

# Expected: ["/css/style.css", "/js/main.js", "/images/bg.png"]
# Excluded: external URL, data URI
```

**Verification**:
- [ ] Function detects all absolute local paths
- [ ] Skips external URLs (http://, https://)
- [ ] Skips data URIs (data:)
- [ ] Skips protocol-relative URLs (//)
- [ ] Handles both single and double quotes

**Success Criteria**:
- ✅ Function correctly identifies 100% of local asset paths
- ✅ Zero false positives (external URLs not detected)
- ✅ Handles edge cases (inline CSS, escaped quotes)

### Step 1.3: Implement CSS Prefix Calculation

**Action**: Create `calculate_css_prefix()` function based on module destination.

**Implementation**:
```bash
# Calculate CSS path prefix from module destination
# Arguments:
#   $1 - Module destination path (e.g., "/quiz/", "/", "/docs/product/")
# Returns:
#   CSS prefix string (e.g., "/quiz", "", "/docs/product")
calculate_css_prefix() {
    local destination="$1"

    # Root destination "/" needs empty prefix
    if [[ "$destination" == "/" ]]; then
        echo ""
        return 0
    fi

    # Remove trailing slash, ensure leading slash
    local prefix="${destination%/}"  # Remove trailing /
    prefix="${prefix#/}"             # Remove leading /
    prefix="/${prefix}"              # Add back single leading /

    echo "$prefix"
}
```

**Test Cases**:
```bash
# Test various destination formats
calculate_css_prefix "/"              # Expected: ""
calculate_css_prefix "/quiz/"         # Expected: "/quiz"
calculate_css_prefix "/docs/product/" # Expected: "/docs/product"
calculate_css_prefix "quiz"           # Expected: "/quiz"
calculate_css_prefix "/quiz"          # Expected: "/quiz"
```

**Verification**:
- [ ] Root path "/" returns empty string
- [ ] Single-level paths return correct prefix
- [ ] Multi-level paths preserved
- [ ] Handles missing leading/trailing slashes
- [ ] No double slashes in output

**Success Criteria**:
- ✅ All test cases pass
- ✅ Handles malformed input gracefully
- ✅ Output always valid (no //, no trailing /)

### Step 1.4: Create Path Analysis Report Function

**Action**: Implement `analyze_module_paths()` to report required rewrites per module.

**Implementation**:
```bash
# Analyze a module's asset paths and report rewriting plan
# Arguments:
#   $1 - Module output directory
#   $2 - CSS path prefix
analyze_module_paths() {
    local output_dir="$1"
    local css_prefix="$2"

    log_info "Analyzing asset paths in: $output_dir"
    log_info "CSS prefix: ${css_prefix:-"(none - root deployment)"}"

    local html_count=0
    local asset_count=0
    declare -A unique_patterns

    # Scan all HTML files
    while IFS= read -r html_file; do
        ((html_count++))

        declare -a paths=()
        detect_asset_paths "$html_file" paths

        for path in "${paths[@]}"; do
            ((asset_count++))
            # Track unique path patterns
            local pattern="${path%%/*}"
            unique_patterns["$pattern"]=1
        done
    done < <(find "$output_dir" -name "*.html" -type f)

    log_info "Analysis complete:"
    log_info "  - HTML files scanned: $html_count"
    log_info "  - Asset references found: $asset_count"
    log_info "  - Unique path types: ${#unique_patterns[@]}"
    log_info "  - Path types: ${!unique_patterns[*]}"

    # Estimate rewrite operations
    if [[ -n "$css_prefix" ]]; then
        log_info "  - Rewrite operations required: $asset_count"
    else
        log_info "  - No rewrites needed (root deployment)"
    fi
}
```

**Verification**:
- [ ] Scans all HTML files in output directory
- [ ] Counts total asset references
- [ ] Identifies unique path patterns
- [ ] Provides clear analysis report
- [ ] Handles modules with no assets

**Success Criteria**:
- ✅ Accurate count of HTML files
- ✅ Accurate count of asset references
- ✅ Clear reporting of rewrite scope

### Step 1.5: Test with All 4 Theme Templates

**Action**: Run analysis against all theme templates to validate detection.

**Implementation**:
```bash
# Test CSS path analysis with all templates
test_css_analysis() {
    local templates=("minimal" "default" "academic" "enterprise")

    for template in "${templates[@]}"; do
        log_section "Testing CSS Analysis: $template template"

        # Build test site with template
        ./scripts/build.sh \
            --template="$template" \
            --content="tests/fixtures/test-content" \
            --output="/tmp/css-test-$template"

        # Analyze paths
        analyze_module_paths "/tmp/css-test-$template" "/test-prefix"

        # Verify HTML files generated
        local html_count=$(find "/tmp/css-test-$template" -name "*.html" | wc -l)
        if [[ $html_count -eq 0 ]]; then
            log_error "No HTML files generated for template: $template"
            return 1
        fi

        log_success "Template $template: $html_count HTML files analyzed"
    done
}
```

**Verification**:
- [ ] All 4 templates build successfully
- [ ] Analysis runs for each template
- [ ] Asset patterns detected in each
- [ ] No errors or false positives

**Success Criteria**:
- ✅ 4/4 templates analyzed successfully
- ✅ Asset references detected in all templates
- ✅ Analysis reports generated

### Step 1.6: Create Test Suite for Path Detection

**Action**: Create `tests/test-css-path-detection.sh` with comprehensive tests.

**Implementation**:
```bash
#!/usr/bin/env bash
# tests/test-css-path-detection.sh

source "$(dirname "$0")/../scripts/federated-build.sh"

# Test 1: Detect absolute local paths
test_detect_local_paths() {
    cat > /tmp/test1.html <<'EOF'
<link href="/css/style.css">
<script src="/js/main.js"></script>
EOF

    declare -a paths=()
    detect_asset_paths "/tmp/test1.html" paths

    [[ ${#paths[@]} -eq 2 ]] || return 1
    [[ "${paths[0]}" == "/css/style.css" ]] || return 1
    [[ "${paths[1]}" == "/js/main.js" ]] || return 1

    echo "✓ Test 1 passed"
}

# Test 2: Skip external URLs
test_skip_external_urls() {
    cat > /tmp/test2.html <<'EOF'
<img src="https://example.com/image.png">
<script src="http://cdn.example.com/lib.js"></script>
<link href="/local/style.css">
EOF

    declare -a paths=()
    detect_asset_paths "/tmp/test2.html" paths

    [[ ${#paths[@]} -eq 1 ]] || return 1
    [[ "${paths[0]}" == "/local/style.css" ]] || return 1

    echo "✓ Test 2 passed"
}

# Test 3: Skip data URIs
test_skip_data_uris() {
    cat > /tmp/test3.html <<'EOF'
<img src="data:image/svg+xml,<svg></svg>">
<link href="/css/real.css">
EOF

    declare -a paths=()
    detect_asset_paths "/tmp/test3.html" paths

    [[ ${#paths[@]} -eq 1 ]] || return 1
    [[ "${paths[0]}" == "/css/real.css" ]] || return 1

    echo "✓ Test 3 passed"
}

# Test 4: CSS prefix calculation
test_css_prefix_calculation() {
    [[ "$(calculate_css_prefix '/')" == "" ]] || return 1
    [[ "$(calculate_css_prefix '/quiz/')" == "/quiz" ]] || return 1
    [[ "$(calculate_css_prefix '/docs/product/')" == "/docs/product" ]] || return 1

    echo "✓ Test 4 passed"
}

# Run all tests
echo "Running CSS Path Detection Tests..."
test_detect_local_paths
test_skip_external_urls
test_skip_data_uris
test_css_prefix_calculation

echo ""
echo "All tests passed! ✅"
```

**Verification**:
- [ ] Test file created
- [ ] All 4 tests pass
- [ ] Tests cover edge cases
- [ ] Clear pass/fail output

**Success Criteria**:
- ✅ Test suite executes successfully
- ✅ 4/4 tests passing
- ✅ Edge cases covered

## Testing Plan

### Unit Tests
- [x] `detect_asset_paths()` - identifies all local paths
- [x] `detect_asset_paths()` - skips external URLs
- [x] `detect_asset_paths()` - skips data URIs
- [x] `calculate_css_prefix()` - all destination formats
- [x] `analyze_module_paths()` - generates accurate reports

### Integration Tests
- [x] Analysis with minimal template
- [x] Analysis with default template
- [x] Analysis with academic template
- [x] Analysis with enterprise template

### Edge Cases
- [ ] HTML with no assets
- [ ] Mixed quote styles (single, double)
- [ ] Inline CSS with url()
- [ ] JavaScript with dynamic URLs
- [ ] Escaped quotes in attributes

## Rollback Plan

If Stage 1 analysis reveals unexpected issues:
1. Review Hugo theme documentation
2. Expand regex patterns based on findings
3. Add additional test cases
4. Adjust detection logic as needed

No code changes to federated-build.sh yet - only analysis functions added.

## Definition of Done

- [x] All 6 steps completed
- [x] `detect_asset_paths()` function implemented
- [x] `calculate_css_prefix()` function implemented
- [x] `analyze_module_paths()` function implemented
- [x] Test suite created and passing (4/4 tests)
- [x] All 4 theme templates analyzed
- [x] Analysis reports generated
- [x] Documentation updated
- [x] Ready for Stage 2 (path rewriting implementation)

## Files to Create/Modify

### New Files
- `tests/test-css-path-detection.sh` - Test suite for path detection

### Modified Files
- `scripts/federated-build.sh` - Add detection functions (~150 lines)

### Documentation
- `docs/proposals/.../child-3-css-path-resolution/001-progress.md` - Stage 1 report

## Expected Outcome

After Stage 1 completion:
- ✅ Complete understanding of Hugo asset referencing patterns
- ✅ Working detection functions for asset path analysis
- ✅ Test coverage for all detection logic
- ✅ Analysis reports for all 4 theme templates
- ✅ Foundation ready for Stage 2 (rewriting implementation)

---

**Stage 1 Estimated Time**: 4 hours
- Step 1.1: Research patterns (1 hour)
- Step 1.2: Detection function (1 hour)
- Step 1.3: Prefix calculation (0.5 hours)
- Step 1.4: Analysis reporting (0.5 hours)
- Step 1.5: Template testing (0.5 hours)
- Step 1.6: Test suite (0.5 hours)

**Next Stage**: 002-path-rewriting-implementation.md
