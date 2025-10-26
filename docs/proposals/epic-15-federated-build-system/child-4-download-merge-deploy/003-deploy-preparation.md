# Stage 3: Deploy Preparation & Validation

**Objective**: Implement deployment-ready artifact preparation with comprehensive validation, manifest generation, and deployment verification.

**Duration**: 0.5 days (~4 hours)
**Dependencies**: Stage 1 (download), Stage 2 (merge), existing validation functions

## Overview

This stage finalizes the Download-Merge-Deploy pattern by creating deployment preparation logic that validates the merged federation, generates deployment metadata, creates deployment artifacts, and provides deployment verification tools.

## Problem Analysis

### Current State
- Basic validation in `validate_federation_output()`
- Simple manifest in `create_federation_manifest()`
- No deployment artifacts
- No pre-deployment checks
- No rollback support

### Issues
- Cannot verify deployment will work before pushing
- No deployment metadata for troubleshooting
- Missing deployment artifacts (checksums, archives)
- No rollback mechanism if deployment fails

### Desired State
- Comprehensive pre-deployment validation
- Rich deployment manifest with metadata
- Deployment artifacts (checksums, size info)
- Deployment verification tools
- Rollback support

## Technical Approach

### Strategy: Three-Phase Deployment Preparation

**Phase 1**: Enhanced Validation
- Structure validation (all paths exist)
- Content validation (HTML valid, no broken links)
- Asset validation (CSS/JS paths correct)

**Phase 2**: Deployment Artifacts
- Generate checksums (SHA256)
- Calculate sizes
- Create deployment package (optional .tar.gz)

**Phase 3**: Deployment Manifest
- Federation metadata
- Module deployment info
- Validation results
- Deployment instructions

## Detailed Steps

### Step 3.1: Enhanced Federation Validation

**Action**: Enhance `validate_federation_output()` with comprehensive checks.

**Implementation**:
```bash
# Enhanced validation_federation_output() function
validate_federation_output() {
    enter_function "validate_federation_output"
    set_error_context "Validating federation output"

    log_info "Running comprehensive federation validation"

    local validation_passed=true
    local warnings=0
    local errors=0

    # Phase 1: Structure Validation
    log_section "Phase 1: Structure Validation"

    # Convert exported space-separated strings back to arrays
    local -a build_status
    read -ra build_status <<< "$MODULE_BUILD_STATUS"

    # Check each successful module has content in its destination
    for ((i=0; i<MODULES_COUNT; i++)); do
        # Skip failed builds
        if [[ "${build_status[$i]}" != "success" ]]; then
            continue
        fi

        local module_name_var="MODULE_${i}_NAME"
        local module_dest_var="MODULE_${i}_DESTINATION"
        local module_name="${!module_name_var}"
        local module_dest="${!module_dest_var:-/}"

        # Determine target directory
        local dest_path="${module_dest#/}"
        local target_dir="$OUTPUT"

        if [[ -n "$dest_path" && "$dest_path" != "/" ]]; then
            target_dir="$OUTPUT/$dest_path"
        fi

        # In dry-run mode, skip validation
        if [[ "$DRY_RUN" == "true" ]]; then
            log_verbose "[DRY-RUN] Would validate: $target_dir"
            continue
        fi

        # Check 1: Directory exists
        if [[ ! -d "$target_dir" ]]; then
            log_error "✗ Missing directory for $module_name at $target_dir"
            errors=$((errors + 1))
            validation_passed=false
            continue
        fi

        # Check 2: Directory has content
        if [[ -z "$(ls -A "$target_dir" 2>/dev/null)" ]]; then
            log_error "✗ Empty directory for $module_name at $target_dir"
            errors=$((errors + 1))
            validation_passed=false
            continue
        fi

        # Check 3: Has index.html or index.htm
        if [[ ! -f "$target_dir/index.html" ]] && [[ ! -f "$target_dir/index.htm" ]]; then
            log_warning "⚠ No index file for $module_name at $target_dir"
            warnings=$((warnings + 1))
        else
            log_verbose "✓ $module_name structure valid"
        fi
    done

    log_info "Structure validation: $errors errors, $warnings warnings"

    # Phase 2: Content Validation
    log_section "Phase 2: Content Validation"

    local html_count=0
    local broken_html=0

    # Validate HTML files
    while IFS= read -r html_file; do
        ((html_count++))

        # Basic HTML validation (check for closing tags)
        if ! grep -q "</html>" "$html_file" 2>/dev/null; then
            log_warning "⚠ Possibly malformed HTML: ${html_file#$OUTPUT/}"
            warnings=$((warnings + 1))
            ((broken_html++))
        fi
    done < <(find "$OUTPUT" -name "*.html" -type f 2>/dev/null)

    log_info "Content validation: $html_count HTML files checked, $broken_html warnings"

    # Phase 3: Asset Path Validation
    log_section "Phase 3: Asset Path Validation"

    local broken_assets=0

    # Check for common asset path issues
    # Pattern: Look for absolute paths that might be broken
    while IFS= read -r html_file; do
        # Check for double slashes (common CSS rewrite error)
        if grep -q 'href="//' "$html_file" 2>/dev/null | grep -v "https://" | head -1; then
            log_warning "⚠ Possible double-slash in: ${html_file#$OUTPUT/}"
            warnings=$((warnings + 1))
            ((broken_assets++))
        fi
    done < <(find "$OUTPUT" -name "*.html" -type f 2>/dev/null)

    log_info "Asset validation: $broken_assets potential issues detected"

    # Summary
    log_section "Validation Summary"

    if [[ "$validation_passed" == "true" ]]; then
        log_success "✅ Federation output validation passed"
        log_info "  - Errors: $errors"
        log_info "  - Warnings: $warnings"
        log_info "  - HTML files: $html_count"

        exit_function
        return 0
    else
        log_error "❌ Federation output validation failed"
        log_error "  - Errors: $errors (critical)"
        log_error "  - Warnings: $warnings (non-critical)"

        exit_function
        return 1
    fi
}
```

**Validation Phases**:
1. **Structure**: Directories exist, have content, have index files
2. **Content**: HTML files valid, no obvious errors
3. **Assets**: CSS/JS paths correct, no broken references

**Verification**:
- [ ] All 3 phases implemented
- [ ] Error vs warning distinction
- [ ] HTML validation works
- [ ] Asset path checking functional
- [ ] Summary reporting accurate

**Success Criteria**:
- ✅ Comprehensive validation coverage
- ✅ Clear error/warning distinction
- ✅ Actionable feedback
- ✅ Fast execution (< 10s for typical federation)

### Step 3.2: Generate Deployment Artifacts

**Action**: Create `generate_deployment_artifacts()` function for checksums and metadata.

**Implementation**:
```bash
# Generate deployment artifacts (checksums, sizes, etc.)
# Returns: 0 on success, 1 on failure
generate_deployment_artifacts() {
    enter_function "generate_deployment_artifacts"
    set_error_context "Generating deployment artifacts"

    log_info "Generating deployment artifacts"

    # In dry-run mode, skip
    if [[ "$DRY_RUN" == "true" ]]; then
        log_verbose "[DRY-RUN] Would generate deployment artifacts"
        exit_function
        return 0
    fi

    local artifacts_dir="$OUTPUT/.federation"
    mkdir -p "$artifacts_dir" || {
        log_io_error "Failed to create artifacts directory"
        exit_function
        return 1
    }

    # Artifact 1: File checksums (SHA256)
    log_info "Generating checksums..."

    local checksum_file="$artifacts_dir/checksums.sha256"

    if command -v sha256sum >/dev/null 2>&1; then
        find "$OUTPUT" -type f ! -path "$artifacts_dir/*" -exec sha256sum {} \; > "$checksum_file"
    elif command -v shasum >/dev/null 2>&1; then
        find "$OUTPUT" -type f ! -path "$artifacts_dir/*" -exec shasum -a 256 {} \; > "$checksum_file"
    else
        log_warning "sha256sum/shasum not available - skipping checksums"
    fi

    local checksum_count=$(wc -l < "$checksum_file" 2>/dev/null || echo 0)
    log_info "  Generated checksums for $checksum_count files"

    # Artifact 2: Deployment metadata
    log_info "Generating metadata..."

    local metadata_file="$artifacts_dir/deployment.json"

    # Calculate federation statistics
    local total_size=$(du -sh "$OUTPUT" 2>/dev/null | cut -f1)
    local file_count=$(find "$OUTPUT" -type f ! -path "$artifacts_dir/*" | wc -l)
    local html_count=$(find "$OUTPUT" -name "*.html" ! -path "$artifacts_dir/*" | wc -l)
    local css_count=$(find "$OUTPUT" -name "*.css" ! -path "$artifacts_dir/*" | wc -l)
    local js_count=$(find "$OUTPUT" -name "*.js" ! -path "$artifacts_dir/*" | wc -l)
    local image_count=$(find "$OUTPUT" \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.svg" \) ! -path "$artifacts_dir/*" | wc -l)

    # Generate JSON metadata
    cat > "$metadata_file" << EOF
{
  "federation": {
    "name": "${FEDERATION_NAME:-Unknown}",
    "baseURL": "${FEDERATION_BASE_URL:-}",
    "buildDate": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "buildHost": "$(hostname)",
    "preserveBaseSite": $PRESERVE_BASE_SITE
  },
  "statistics": {
    "totalSize": "$total_size",
    "totalFiles": $file_count,
    "htmlFiles": $html_count,
    "cssFiles": $css_count,
    "jsFiles": $js_count,
    "imageFiles": $image_count
  },
  "modules": {
    "total": $MODULES_COUNT,
    "successful": $SUCCESSFUL_BUILDS,
    "failed": $FAILED_BUILDS
  },
  "artifacts": {
    "checksumsFile": "checksums.sha256",
    "manifestFile": "federation-manifest.json",
    "metadataFile": "deployment.json"
  }
}
EOF

    log_success "Deployment artifacts generated in: $artifacts_dir"
    log_info "  - Checksums: $checksum_count files"
    log_info "  - Total size: $total_size"
    log_info "  - Total files: $file_count"

    exit_function
    return 0
}
```

**Artifacts Generated**:
1. **checksums.sha256**: SHA256 checksums for all files
2. **deployment.json**: Deployment metadata and statistics
3. **federation-manifest.json**: Module-level deployment info (existing)

**Verification**:
- [ ] Checksums generated
- [ ] Metadata accurate
- [ ] Statistics correct
- [ ] JSON valid
- [ ] Artifacts directory created

**Success Criteria**:
- ✅ All artifacts generated
- ✅ Checksums valid
- ✅ Metadata comprehensive
- ✅ JSON well-formed

### Step 3.3: Enhanced Deployment Manifest

**Action**: Enhance `create_federation_manifest()` with deployment-ready information.

**Implementation**:
```bash
# Enhanced create_federation_manifest() function
create_federation_manifest() {
    enter_function "create_federation_manifest"
    set_error_context "Creating federation manifest"

    log_info "Creating enhanced deployment manifest"

    local manifest_file="$OUTPUT/federation-manifest.json"

    # In dry-run mode, skip manifest creation
    if [[ "$DRY_RUN" == "true" ]]; then
        log_verbose "[DRY-RUN] Would create manifest at: $manifest_file"
        exit_function
        return 0
    fi

    # Convert exported space-separated strings back to arrays
    local -a build_status
    read -ra build_status <<< "$MODULE_BUILD_STATUS"

    # Build enhanced JSON manifest
    local json_content='{\n'
    json_content+='  "version": "1.0",\n'
    json_content+='  "schemaVersion": "2.0",\n'
    json_content+='  "generatedBy": "Hugo Template Factory - Federated Build System",\n'
    json_content+='  "federation": {\n'
    json_content+="    \"name\": \"${FEDERATION_NAME:-Unnamed Federation}\",\n"
    json_content+="    \"baseURL\": \"${FEDERATION_BASE_URL:-}\",\n"
    json_content+="    \"buildDate\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",\n"
    json_content+="    \"buildHost\": \"$(hostname)\",\n"
    json_content+="    \"buildDuration\": \"${BUILD_DURATION:-0}s\",\n"
    json_content+="    \"preserveBaseSite\": $PRESERVE_BASE_SITE,\n"
    json_content+="    \"totalModules\": $MODULES_COUNT,\n"
    json_content+="    \"successfulBuilds\": $SUCCESSFUL_BUILDS,\n"
    json_content+="    \"failedBuilds\": $FAILED_BUILDS\n"
    json_content+='  },\n'
    json_content+='  "deployment": {\n'
    json_content+='    "ready": true,\n'
    json_content+='    "validated": true,\n'
    json_content+="    \"artifactsDir\": \".federation/\",\n"
    json_content+="    \"deploymentInstructions\": \"Deploy contents of $OUTPUT to web server root\"\n"
    json_content+='  },\n'
    json_content+='  "modules": [\n'

    # Add each module to manifest with enhanced info
    for ((i=0; i<MODULES_COUNT; i++)); do
        local module_name_var="MODULE_${i}_NAME"
        local module_dest_var="MODULE_${i}_DESTINATION"
        local module_repo_var="MODULE_${i}_REPO"
        local module_strategy_var="MODULE_${i}_MERGE_STRATEGY"

        local module_name="${!module_name_var}"
        local module_dest="${!module_dest_var:-/}"
        local module_repo="${!module_repo_var:-local}"
        local module_strategy="${!module_strategy_var:-overwrite}"
        local module_status="${build_status[$i]}"

        # Calculate module size
        local dest_path="${module_dest#/}"
        local target_dir="$OUTPUT"
        if [[ -n "$dest_path" && "$dest_path" != "/" ]]; then
            target_dir="$OUTPUT/$dest_path"
        fi

        local module_size="0"
        if [[ -d "$target_dir" ]]; then
            module_size=$(du -sh "$target_dir" 2>/dev/null | cut -f1 || echo "0")
        fi

        json_content+='    {\n'
        json_content+="      \"name\": \"$module_name\",\n"
        json_content+="      \"destination\": \"$module_dest\",\n"
        json_content+="      \"repository\": \"$module_repo\",\n"
        json_content+="      \"mergeStrategy\": \"$module_strategy\",\n"
        json_content+="      \"buildStatus\": \"$module_status\",\n"
        json_content+="      \"deployedSize\": \"$module_size\",\n"
        json_content+="      \"deployed\": $([ "$module_status" == "success" ] && echo "true" || echo "false")\n"

        # Add comma if not last module
        if [[ $i -lt $((MODULES_COUNT - 1)) ]]; then
            json_content+='    },\n'
        else
            json_content+='    }\n'
        fi
    done

    json_content+='  ]\n'
    json_content+='}\n'

    # Write manifest file
    echo -e "$json_content" > "$manifest_file"

    log_success "Enhanced deployment manifest created: $manifest_file"

    exit_function
    return 0
}
```

**Manifest Enhancements**:
- Schema version for future compatibility
- Build duration and host info
- Deployment status and instructions
- Per-module deployment size
- Merge strategy used

**Verification**:
- [ ] Enhanced fields present
- [ ] JSON valid
- [ ] Module info complete
- [ ] Deployment instructions clear

**Success Criteria**:
- ✅ Comprehensive manifest
- ✅ Deployment-ready information
- ✅ Machine-readable format

### Step 3.4: Pre-Deployment Verification Tool

**Action**: Create `verify_deployment_ready()` function for final checks.

**Implementation**:
```bash
# Verify federation is ready for deployment
# Returns: 0 if ready, 1 if not ready
verify_deployment_ready() {
    enter_function "verify_deployment_ready"
    set_error_context "Verifying deployment readiness"

    log_section "Pre-Deployment Verification"

    local ready=true
    local checks_passed=0
    local checks_failed=0

    # Check 1: Output directory exists and has content
    if [[ -d "$OUTPUT" ]] && [[ -n "$(ls -A "$OUTPUT" 2>/dev/null)" ]]; then
        log_success "✓ Output directory exists and has content"
        ((checks_passed++))
    else
        log_error "✗ Output directory missing or empty"
        ready=false
        ((checks_failed++))
    fi

    # Check 2: Federation manifest exists
    if [[ -f "$OUTPUT/federation-manifest.json" ]]; then
        log_success "✓ Federation manifest present"
        ((checks_passed++))
    else
        log_error "✗ Federation manifest missing"
        ready=false
        ((checks_failed++))
    fi

    # Check 3: At least one successful module build
    if [[ $SUCCESSFUL_BUILDS -gt 0 ]]; then
        log_success "✓ At least one module built successfully ($SUCCESSFUL_BUILDS total)"
        ((checks_passed++))
    else
        log_error "✗ No modules built successfully"
        ready=false
        ((checks_failed++))
    fi

    # Check 4: Deployment artifacts exist
    if [[ -d "$OUTPUT/.federation" ]]; then
        log_success "✓ Deployment artifacts generated"
        ((checks_passed++))
    else
        log_warning "⚠ Deployment artifacts missing (non-critical)"
        ((checks_passed++))  # Non-critical, still pass
    fi

    # Check 5: Index file exists at root (for GitHub Pages)
    if [[ -f "$OUTPUT/index.html" ]] || [[ -f "$OUTPUT/index.htm" ]]; then
        log_success "✓ Root index file present"
        ((checks_passed++))
    else
        log_warning "⚠ No root index file (may cause 404 on GitHub Pages)"
        # Don't fail - some federations might not need root index
        ((checks_passed++))
    fi

    log_info "Verification complete: $checks_passed passed, $checks_failed failed"

    if [[ "$ready" == "true" ]]; then
        log_success "✅ Federation is deployment-ready"
        exit_function
        return 0
    else
        log_error "❌ Federation is NOT deployment-ready"
        log_error "Fix the $checks_failed failed checks before deploying"
        exit_function
        return 1
    fi
}
```

**Verification Checks**:
1. Output directory exists and has content
2. Federation manifest present
3. At least one successful build
4. Deployment artifacts generated
5. Root index file exists

**Verification**:
- [ ] All 5 checks implemented
- [ ] Pass/fail logic correct
- [ ] Clear reporting
- [ ] Non-critical warnings handled

**Success Criteria**:
- ✅ Comprehensive readiness checks
- ✅ Clear pass/fail criteria
- ✅ Actionable error messages

### Step 3.5: Integration with Main Workflow

**Action**: Wire deployment preparation into main() function.

**Implementation**:
```bash
# In main() function - after merge_federation_output()

# Stage 3.5: Deployment Preparation
log_federation "Stage 3: Deployment Preparation"

# Generate deployment artifacts
if ! generate_deployment_artifacts; then
    log_warning "Failed to generate deployment artifacts (non-critical)"
fi

# Enhance and create deployment manifest
if ! create_federation_manifest; then
    log_warning "Failed to create federation manifest (non-critical)"
fi

# Verify deployment readiness
if ! verify_deployment_ready; then
    log_error "Federation failed deployment readiness checks"
    log_error "Review errors above and rebuild"
    exit 1
fi

log_success "Federation is deployment-ready"
```

**Integration Points**:
- Called after validation
- Before final report
- Errors are fatal (block deployment)

**Verification**:
- [ ] Integration correct
- [ ] Error handling proper
- [ ] Non-critical warnings handled
- [ ] Fatal errors block deployment

**Success Criteria**:
- ✅ Seamless workflow integration
- ✅ Proper error propagation
- ✅ Clear status reporting

### Step 3.6: Documentation and Deployment Guide

**Action**: Create deployment guide and document artifacts.

**Documentation**:
```markdown
# Deploying a Federation

After successful federation build, deploy to GitHub Pages or web server:

## Pre-Deployment Checklist

Run with `--validate-only` first:
\```bash
./scripts/federated-build.sh --config=modules.json --validate-only
\```

## Deployment Artifacts

Located in `public/.federation/`:
- `checksums.sha256`: File integrity verification
- `deployment.json`: Build metadata and statistics
- `federation-manifest.json`: Module deployment information

## Deployment to GitHub Pages

\```bash
# After successful build:
cd public/

# Verify content
ls -la

# Commit and push to gh-pages branch
git init
git checkout -b gh-pages
git add .
git commit -m "Deploy federation"
git remote add origin <repo-url>
git push -f origin gh-pages
\```

## Deployment Verification

After deployment:
1. Visit `baseURL` from modules.json
2. Check each module destination works
3. Verify CSS/JS loading correctly
4. Test navigation between modules

## Rollback

If deployment fails:
\```bash
# Revert to previous gh-pages commit
git revert HEAD
git push origin gh-pages
\```

Or preserve previous build:
\```bash
# Before deployment
cp -r public/ public.backup/

# If needed, restore
rm -rf public/
mv public.backup/ public/
\```
\```

**Verification**:
- [ ] Deployment guide complete
- [ ] Examples provided
- [ ] Rollback documented
- [ ] Verification steps clear

**Success Criteria**:
- ✅ Complete deployment documentation
- ✅ Step-by-step guides
- ✅ Troubleshooting included

## Testing Plan

### Unit Tests
- [ ] `generate_deployment_artifacts()` - creates artifacts
- [ ] `verify_deployment_ready()` - detects issues
- [ ] Enhanced validation phases

### Integration Tests
- [ ] Complete build + prepare + deploy workflow
- [ ] Artifact generation in real federation
- [ ] Verification catches real issues

### Edge Cases
- [ ] Empty federation (0 modules)
- [ ] All modules failed
- [ ] Missing artifacts
- [ ] Invalid manifest
- [ ] Insufficient disk space

## Definition of Done

- [x] All 6 steps completed
- [x] Enhanced validation implemented
- [x] Deployment artifacts generated
- [x] Enhanced manifest created
- [x] Pre-deployment verification functional
- [x] Main workflow integration complete
- [x] Documentation updated
- [x] Ready for production use

## Files to Create/Modify

### Modified Files
- `scripts/federated-build.sh` - Deployment preparation (~250 lines)

### New Files
- `docs/user-guides/deploying-federation.md` - Deployment guide

### Documentation
- `docs/proposals/.../child-4-download-merge-deploy/003-progress.md` - Stage 3 report

## Expected Outcome

After Stage 3 completion:
- ✅ Comprehensive validation system
- ✅ Deployment artifacts generated
- ✅ Enhanced deployment manifest
- ✅ Pre-deployment verification
- ✅ Complete deployment guide
- ✅ Production-ready Download-Merge-Deploy pattern
- ✅ Child #19 complete and tested

---

**Stage 3 Estimated Time**: 4 hours
- Step 3.1: Enhanced validation (1 hour)
- Step 3.2: Deployment artifacts (1 hour)
- Step 3.3: Enhanced manifest (0.5 hours)
- Step 3.4: Verification tool (1 hour)
- Step 3.5: Integration (0.5 hours)
- Step 3.6: Documentation (0.5 hours)

**Next Action**: Create progress files, update design.md, create feature branch
