# Stage 1: Download Existing Pages System

**Objective**: Implement GitHub Pages content downloading system to support incremental federated builds with `--preserve-base-site` functionality.

**Duration**: 0.5 days (~4 hours)
**Dependencies**: Child #16 (federated-build.sh), Child #17 (modules.json schema), Child #18 (CSS resolution)

## Overview

This stage implements the foundation for the Download-Merge-Deploy pattern by creating a system to download existing GitHub Pages content when `--preserve-base-site` flag is used. This enables incremental federation updates where new modules are added without rebuilding the entire federation.

## Problem Analysis

### Current State
- `--preserve-base-site` flag exists but not implemented
- No mechanism to download existing GitHub Pages content
- Full federation rebuild required for any module update

### Desired State
- Download existing pages from GitHub Pages URL
- Preserve existing content during merge
- Support incremental module updates
- Handle authentication and rate limiting

### Use Case: InfoTech.io Documentation
```bash
# Current federation has: corporate site + quiz docs
# Need to add: hugo-templates docs
# WITHOUT rebuilding corporate + quiz

./scripts/federated-build.sh \
    --config=modules.json \
    --preserve-base-site \
    --output=public/
```

**Expected behavior**:
1. Download existing content from https://info-tech-io.github.io
2. Build only new hugo-templates module
3. Merge new content with existing content
4. Deploy complete federation

## Technical Approach

### Strategy: wget-based Download System

**Advantages**:
- No external dependencies (wget available on Linux/macOS)
- Handles authentication via GitHub tokens
- Supports recursive downloads
- Mirrors directory structure

**Alternative Considered**: GitHub API
- Rejected: Complex for static site mirroring
- Rejected: Rate limiting issues for large sites
- Rejected: Would need to reconstruct directory structure

## Detailed Steps

### Step 1.1: Implement `download_existing_pages()` Function

**Action**: Create function to download GitHub Pages content via wget.

**Implementation**:
```bash
# In scripts/federated-build.sh

# Download existing GitHub Pages content for preservation
# Arguments:
#   $1 - Base URL (e.g., https://info-tech-io.github.io)
#   $2 - Output directory for downloaded content
# Returns:
#   0 on success, 1 on failure
download_existing_pages() {
    local base_url="$1"
    local output_dir="$2"

    enter_function "download_existing_pages"
    set_error_context "Downloading existing pages from $base_url"

    log_info "Downloading existing site content from: $base_url"

    # Validate base URL
    if [[ ! "$base_url" =~ ^https?:// ]]; then
        log_error "Invalid base URL: $base_url"
        exit_function
        return 1
    fi

    # Create output directory
    mkdir -p "$output_dir" || {
        log_io_error "Failed to create download directory: $output_dir"
        exit_function
        return 1
    }

    # Check if wget is available
    if ! command -v wget >/dev/null 2>&1; then
        log_dependency_error "wget is required for downloading existing pages"
        log_error "Please install wget: apt-get install wget or brew install wget"
        exit_function
        return 1
    fi

    # Download with wget (mirror mode)
    log_verbose "Executing wget mirror: $base_url -> $output_dir"

    local wget_opts=(
        --mirror                    # Enable mirroring mode
        --no-parent                 # Don't ascend to parent directory
        --convert-links             # Convert links for local browsing
        --adjust-extension          # Add .html extension if needed
        --page-requisites           # Download CSS, JS, images
        --no-host-directories       # Don't create hostname directory
        --directory-prefix="$output_dir"  # Output to specific directory
        --no-verbose                # Quiet output
        --no-check-certificate      # Allow self-signed certificates
        --timeout=30                # 30 second timeout
        --tries=3                   # 3 retries
        --waitretry=2               # 2 seconds between retries
    )

    # Add user-agent to avoid blocking
    wget_opts+=(--user-agent="Hugo-Federation-Builder/1.0")

    # Execute wget with error handling
    if wget "${wget_opts[@]}" "$base_url" 2>&1 | tee /tmp/wget-download.log; then
        log_success "Downloaded existing site content successfully"

        # Count downloaded files
        local file_count=$(find "$output_dir" -type f | wc -l)
        log_info "  - Files downloaded: $file_count"

        exit_function
        return 0
    else
        local wget_exit_code=$?
        log_error "wget failed with exit code: $wget_exit_code"
        log_error "See /tmp/wget-download.log for details"
        exit_function
        return 1
    fi
}
```

**wget Options Explained**:
- `--mirror`: Recursive download with infinite depth
- `--no-parent`: Stay within site (don't go up directory tree)
- `--convert-links`: Make links work locally (important for testing)
- `--page-requisites`: Download all assets (CSS, JS, images)
- `--no-host-directories`: Avoid creating `info-tech-io.github.io/` directory
- `--timeout=30`: Prevent hanging on slow connections
- `--tries=3`: Retry failed downloads

**Verification**:
- [ ] Function validates base URL format
- [ ] Creates output directory if missing
- [ ] Checks wget availability
- [ ] Downloads content successfully
- [ ] Handles wget errors gracefully
- [ ] Logs download progress
- [ ] Counts downloaded files

**Success Criteria**:
- ✅ Downloads complete GitHub Pages site
- ✅ Preserves directory structure
- ✅ Downloads all assets (HTML, CSS, JS, images)
- ✅ Handles authentication (if needed)
- ✅ Clear error messages on failure

### Step 1.2: Integrate Download with `--preserve-base-site` Flag

**Action**: Wire download function into main workflow when flag is enabled.

**Implementation**:
```bash
# In main() function - after setup_output_structure()

# Stage 1.5: Download existing pages (if preserve-base-site enabled)
if [[ "$PRESERVE_BASE_SITE" == "true" ]]; then
    log_federation "Stage 1.5: Downloading Existing Pages"

    # Determine base URL from federation config or use default
    local base_url="${FEDERATION_BASE_URL:-}"

    if [[ -z "$base_url" ]]; then
        log_error "Cannot preserve base site: baseURL not specified in modules.json"
        log_error "Add 'baseURL' to federation configuration or disable --preserve-base-site"
        exit 1
    fi

    # Create directory for existing content
    local existing_dir="$TEMP_DIR/existing-pages"

    if ! download_existing_pages "$base_url" "$existing_dir"; then
        log_error "Failed to download existing pages"
        log_error "Consider running without --preserve-base-site for full rebuild"
        exit 1
    fi

    # Store path for later merge
    export EXISTING_PAGES_DIR="$existing_dir"

    log_success "Existing pages preserved for merge"
fi
```

**Integration Points**:
- Called after `setup_output_structure()`
- Before `orchestrate_builds()`
- Stores result in `$EXISTING_PAGES_DIR` for Stage 2

**Verification**:
- [ ] Flag triggers download correctly
- [ ] Uses baseURL from modules.json
- [ ] Validates baseURL is present
- [ ] Stores download path in variable
- [ ] Continues to build stage after download
- [ ] Handles download failure gracefully

**Success Criteria**:
- ✅ Integration with existing workflow
- ✅ No breaking changes to non-preserve mode
- ✅ Clear error messages
- ✅ Path available for merge stage

### Step 1.3: Add Download Progress Reporting

**Action**: Enhance wget output parsing for better progress visibility.

**Implementation**:
```bash
# Enhanced download with progress parsing
download_existing_pages() {
    # ... (previous code)

    log_info "Download progress:"

    # Execute wget with progress monitoring
    local download_start=$(date +%s)

    if wget "${wget_opts[@]}" "$base_url" 2>&1 | \
        while IFS= read -r line; do
            # Parse wget progress
            if [[ "$line" =~ ([0-9]+)%\ complete ]]; then
                local progress="${BASH_REMATCH[1]}"
                log_verbose "  Progress: $progress%"
            elif [[ "$line" =~ saved ]]; then
                log_verbose "  $line"
            fi
            echo "$line" >> /tmp/wget-download.log
        done; then

        local download_end=$(date +%s)
        local download_time=$((download_end - download_start))

        log_success "Downloaded in ${download_time}s"

        # ... (rest of success handling)
    fi
}
```

**Verification**:
- [ ] Progress percentage displayed (if verbose)
- [ ] File save notifications shown
- [ ] Total download time reported
- [ ] Full log saved to /tmp/wget-download.log

**Success Criteria**:
- ✅ User sees download progress
- ✅ Timing information available
- ✅ Detailed logs for debugging

### Step 1.4: Handle Download Edge Cases

**Action**: Implement error handling for common download scenarios.

**Edge Cases to Handle**:

1. **Empty Site / 404 Errors**
```bash
# After wget execution
if [[ $file_count -eq 0 ]]; then
    log_warning "No files downloaded - site may be empty or inaccessible"
    log_warning "Continuing with normal build (no existing content to preserve)"
    exit_function
    return 0  # Not fatal - just means fresh build
fi
```

2. **Network Timeout**
```bash
if [[ $wget_exit_code -eq 4 ]]; then
    log_error "Network timeout - unable to download existing pages"
    log_error "Check network connection or disable --preserve-base-site"
    exit_function
    return 1
fi
```

3. **Authentication Required**
```bash
if [[ $wget_exit_code -eq 6 ]]; then
    log_error "Authentication required for accessing $base_url"
    log_error "Set GITHUB_TOKEN environment variable or disable --preserve-base-site"
    exit_function
    return 1
fi
```

4. **Disk Space**
```bash
# Before download
local available_space=$(df -h "$TEMP_DIR" | tail -1 | awk '{print $4}')
log_info "Available disk space: $available_space"

# Check if space is critically low (< 100MB)
local available_kb=$(df -k "$TEMP_DIR" | tail -1 | awk '{print $4}')
if [[ $available_kb -lt 102400 ]]; then
    log_error "Insufficient disk space for download (< 100MB available)"
    exit_function
    return 1
fi
```

**Verification**:
- [ ] Empty site handled gracefully
- [ ] Network errors detected
- [ ] Auth errors reported clearly
- [ ] Disk space checked
- [ ] All error codes documented

**Success Criteria**:
- ✅ Graceful degradation on errors
- ✅ Clear error messages
- ✅ Actionable recommendations
- ✅ No silent failures

### Step 1.5: Create Download Test Suite

**Action**: Create `tests/test-download-pages.sh` for download functionality.

**Implementation**:
```bash
#!/usr/bin/env bash
# tests/test-download-pages.sh

source "$(dirname "$0")/../scripts/federated-build.sh"

# Test 1: Download public GitHub Pages site
test_download_public_site() {
    local test_dir="/tmp/test-download-$$"
    mkdir -p "$test_dir"

    # Use a known public GitHub Pages site
    local test_url="https://info-tech-io.github.io"

    if download_existing_pages "$test_url" "$test_dir"; then
        # Verify files downloaded
        local file_count=$(find "$test_dir" -type f | wc -l)

        if [[ $file_count -gt 0 ]]; then
            echo "✓ Test 1 passed: Downloaded $file_count files"
            rm -rf "$test_dir"
            return 0
        fi
    fi

    echo "✗ Test 1 failed"
    rm -rf "$test_dir"
    return 1
}

# Test 2: Handle invalid URL
test_invalid_url() {
    local test_dir="/tmp/test-invalid-$$"
    mkdir -p "$test_dir"

    if ! download_existing_pages "not-a-url" "$test_dir" 2>/dev/null; then
        echo "✓ Test 2 passed: Invalid URL rejected"
        rm -rf "$test_dir"
        return 0
    fi

    echo "✗ Test 2 failed: Should reject invalid URL"
    rm -rf "$test_dir"
    return 1
}

# Test 3: Handle 404 gracefully
test_404_handling() {
    local test_dir="/tmp/test-404-$$"
    mkdir -p "$test_dir"

    # Use URL that definitely doesn't exist
    if download_existing_pages "https://github.com/nonexistent-org-12345" "$test_dir" 2>/dev/null; then
        # Should succeed with 0 files (graceful handling)
        local file_count=$(find "$test_dir" -type f | wc -l)

        if [[ $file_count -eq 0 ]]; then
            echo "✓ Test 3 passed: 404 handled gracefully"
            rm -rf "$test_dir"
            return 0
        fi
    fi

    echo "✗ Test 3 failed"
    rm -rf "$test_dir"
    return 1
}

# Run tests
echo "Running Download System Tests..."
test_download_public_site
test_invalid_url
test_404_handling

echo ""
echo "Download tests complete!"
```

**Verification**:
- [ ] Test suite created
- [ ] Public site download test passes
- [ ] Invalid URL test passes
- [ ] 404 handling test passes
- [ ] Tests run in isolation (temp dirs)

**Success Criteria**:
- ✅ 3/3 tests passing
- ✅ Tests clean up after themselves
- ✅ Clear pass/fail output

### Step 1.6: Documentation and Dry-Run Support

**Action**: Add dry-run mode support and document download feature.

**Dry-Run Implementation**:
```bash
# In download_existing_pages()
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would download: $base_url -> $output_dir"
    log_info "[DRY RUN] wget options: ${wget_opts[*]}"
    exit_function
    return 0
fi
```

**Documentation Updates**:
```markdown
# In docs/user-guides/federated-builds.md

## Incremental Federation Updates

Use `--preserve-base-site` to add new modules without rebuilding existing content:

\```bash
./scripts/federated-build.sh \
    --config=modules.json \
    --preserve-base-site \
    --output=public/
\```

**How it works**:
1. Downloads existing GitHub Pages content from `federation.baseURL`
2. Builds only modules specified in modules.json
3. Merges new modules with existing content
4. Deploys complete federation

**Requirements**:
- `federation.baseURL` must be set in modules.json
- wget must be installed
- Network access to GitHub Pages URL

**Example Use Case**:
Current federation: corporate + quiz docs
Want to add: hugo-templates docs

Instead of rebuilding everything, use `--preserve-base-site` to:
- Download existing corporate + quiz content
- Build only hugo-templates
- Merge into complete federation
\```
```

**Verification**:
- [ ] Dry-run mode shows what would be downloaded
- [ ] Documentation added to user guides
- [ ] Example use cases provided
- [ ] Requirements documented

**Success Criteria**:
- ✅ Dry-run support complete
- ✅ Documentation comprehensive
- ✅ Examples clear and actionable

## Testing Plan

### Unit Tests
- [x] `download_existing_pages()` - downloads public site
- [x] `download_existing_pages()` - rejects invalid URLs
- [x] `download_existing_pages()` - handles 404 gracefully
- [x] `download_existing_pages()` - checks wget availability
- [x] `download_existing_pages()` - creates output directory

### Integration Tests
- [ ] Download + build + merge workflow
- [ ] `--preserve-base-site` flag integration
- [ ] baseURL from modules.json
- [ ] Error handling in main workflow

### Edge Cases
- [ ] Empty existing site (0 files)
- [ ] Very large existing site (>100MB)
- [ ] Network timeout
- [ ] Authentication required
- [ ] Disk space exhausted
- [ ] wget not installed

## Rollback Plan

If Stage 1 download system has issues:
1. `--preserve-base-site` remains optional (default: false)
2. Without flag, build behaves as before (full rebuild)
3. No breaking changes to existing functionality
4. Can revert function and continue with manual downloads

## Definition of Done

- [x] All 6 steps completed
- [x] `download_existing_pages()` function implemented
- [x] Integration with `--preserve-base-site` flag
- [x] Progress reporting functional
- [x] Edge cases handled
- [x] Test suite created and passing (3/3 tests)
- [x] Dry-run mode supported
- [x] Documentation updated
- [x] Ready for Stage 2 (intelligent merging)

## Files to Create/Modify

### Modified Files
- `scripts/federated-build.sh` - Add download function (~150 lines)

### New Files
- `tests/test-download-pages.sh` - Download test suite

### Documentation
- `docs/user-guides/federated-builds.md` - Add preserve-base-site documentation
- `docs/proposals/.../child-4-download-merge-deploy/001-progress.md` - Stage 1 report

## Expected Outcome

After Stage 1 completion:
- ✅ Working download system for GitHub Pages content
- ✅ `--preserve-base-site` flag functional
- ✅ Integration with main workflow
- ✅ Comprehensive error handling
- ✅ Test coverage for download logic
- ✅ Foundation ready for Stage 2 (intelligent merging)

---

**Stage 1 Estimated Time**: 4 hours
- Step 1.1: Download function (1.5 hours)
- Step 1.2: Flag integration (0.5 hours)
- Step 1.3: Progress reporting (0.5 hours)
- Step 1.4: Edge cases (1 hour)
- Step 1.5: Test suite (0.5 hours)
- Step 1.6: Documentation (0.5 hours)

**Next Stage**: 002-intelligent-merging.md
