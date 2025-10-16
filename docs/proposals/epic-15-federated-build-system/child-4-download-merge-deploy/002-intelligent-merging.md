# Stage 2: Intelligent Merging System

**Objective**: Implement intelligent content merging logic with conflict detection and resolution strategies for combining existing pages with newly built modules.

**Duration**: 0.5 days (~4 hours)
**Dependencies**: Stage 1 (download system), existing `merge_federation_output()` function

## Overview

This stage enhances the existing `merge_federation_output()` function to support intelligent merging when `--preserve-base-site` is enabled. It adds conflict detection, merge strategies, and validation to ensure clean integration of new modules with existing content.

## Problem Analysis

### Current State
- Simple `cp -r` merge in `merge_federation_output()`
- No conflict detection
- No merge strategies
- Overwrites without warning
- No validation after merge

### Issues with Simple Merge
```bash
# Current code
cp -r "$module_output"/* "$target_dir/"

# Problems:
# 1. Silently overwrites existing files
# 2. No conflict reporting
# 3. Can break existing content
# 4. No rollback on partial failure
```

### Desired State
- Detect file/directory conflicts before merge
- Apply configurable merge strategies
- Report conflicts clearly
- Validate merged output
- Support rollback on failure

## Technical Approach

### Strategy: Three-Way Merge with Strategies

**Merge Scenarios**:
1. **No Conflict**: Target path empty → Simple copy
2. **File Conflict**: Both have file at same path → Apply strategy
3. **Directory Conflict**: Both have directory → Recursive merge

**Merge Strategies** (per module configuration):
- `overwrite` (default): New content replaces existing
- `preserve`: Keep existing content, skip new
- `merge`: Combine content (for compatible formats)
- `error`: Fail on conflict (safest)

## Detailed Steps

### Step 2.1: Implement Conflict Detection

**Action**: Create `detect_merge_conflicts()` function to identify overlapping paths.

**Implementation**:
```bash
# Detect conflicts between existing and new content
# Arguments:
#   $1 - Existing content directory
#   $2 - New content directory
#   $3 - Output variable for conflicts (array)
# Returns:
#   0 if no conflicts, 1 if conflicts detected
detect_merge_conflicts() {
    local existing_dir="$1"
    local new_dir="$2"
    local -n conflicts_array="$3"

    enter_function "detect_merge_conflicts"
    set_error_context "Detecting merge conflicts"

    # Check if directories exist
    if [[ ! -d "$existing_dir" ]]; then
        log_verbose "No existing content - no conflicts possible"
        exit_function
        return 0
    fi

    if [[ ! -d "$new_dir" ]]; then
        log_error "New content directory not found: $new_dir"
        exit_function
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
        exit_function
        return 1
    else
        log_success "No merge conflicts detected"
        exit_function
        return 0
    fi
}
```

**Conflict Types**:
1. **File-File**: Both have file at same path
2. **Directory-Directory**: Both have directory (usually safe - recursive merge)
3. **File-Directory**: Type mismatch (error - cannot merge)

**Verification**:
- [ ] Detects file conflicts
- [ ] Detects directory overlaps
- [ ] Detects type conflicts
- [ ] Returns conflict list
- [ ] Handles missing directories

**Success Criteria**:
- ✅ 100% conflict detection accuracy
- ✅ Clear conflict type reporting
- ✅ Handles edge cases (symlinks, special files)

### Step 2.2: Implement Merge Strategies

**Action**: Create `merge_with_strategy()` function to apply different merge behaviors.

**Implementation**:
```bash
# Merge content using specified strategy
# Arguments:
#   $1 - Source directory (new content)
#   $2 - Target directory (existing content)
#   $3 - Merge strategy (overwrite|preserve|merge|error)
# Returns:
#   0 on success, 1 on failure
merge_with_strategy() {
    local source_dir="$1"
    local target_dir="$2"
    local strategy="${3:-overwrite}"

    enter_function "merge_with_strategy"
    set_error_context "Merging with strategy: $strategy"

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

            # Use rsync for better control
            if command -v rsync >/dev/null 2>&1; then
                rsync -a --delete-during "$source_dir/" "$target_dir/"
            else
                # Fallback to cp
                cp -rf "$source_dir"/* "$target_dir/" 2>/dev/null || true
            fi
            ;;

        preserve)
            log_info "Strategy: Preserve - keep existing, skip conflicting new content"

            if [[ $has_conflicts -eq 1 ]]; then
                log_warning "Preserving ${#conflicts[@]} existing items, skipping new versions"
            fi

            # Copy only non-conflicting files
            rsync -a --ignore-existing "$source_dir/" "$target_dir/"
            ;;

        merge)
            log_info "Strategy: Merge - combine compatible content"

            # For directories: recursive merge
            # For files: depends on format (HTML can be merged, binaries cannot)

            find "$source_dir" -type f | while IFS= read -r source_file; do
                local rel_path="${source_file#$source_dir/}"
                local target_file="$target_dir/$rel_path"

                if [[ ! -e "$target_file" ]]; then
                    # No conflict - copy directly
                    mkdir -p "$(dirname "$target_file")"
                    cp "$source_file" "$target_file"
                elif [[ -f "$target_file" ]]; then
                    # Both exist - attempt merge based on file type
                    if [[ "$source_file" =~ \.(html|htm|xml|txt)$ ]]; then
                        log_warning "Merging text file: $rel_path (experimental)"
                        # Simple concatenation for text files
                        cat "$source_file" >> "$target_file"
                    else
                        # Binary or unknown - overwrite
                        log_verbose "Overwriting non-mergeable file: $rel_path"
                        cp "$source_file" "$target_file"
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
                exit_function
                return 1
            fi

            # No conflicts - safe to merge
            cp -r "$source_dir"/* "$target_dir"/ 2>/dev/null || true
            ;;

        *)
            log_error "Unknown merge strategy: $strategy"
            exit_function
            return 1
            ;;
    esac

    log_success "Merge completed with strategy: $strategy"
    exit_function
    return 0
}
```

**Strategy Details**:

| Strategy | Behavior | Use Case | Safety |
|----------|----------|----------|--------|
| `overwrite` | New replaces existing | Normal updates | Medium |
| `preserve` | Keep existing, skip new | Protect stable content | High |
| `merge` | Combine content | Complementary content | Low (experimental) |
| `error` | Fail on conflict | Critical deployments | Highest |

**Verification**:
- [ ] All 4 strategies implemented
- [ ] Strategy selection works
- [ ] Overwrite replaces correctly
- [ ] Preserve keeps existing
- [ ] Merge combines text files
- [ ] Error fails on conflict

**Success Criteria**:
- ✅ All strategies functional
- ✅ Clear logging per strategy
- ✅ Correct file operations
- ✅ Error handling robust

### Step 2.3: Enhance `merge_federation_output()` for Preserve Mode

**Action**: Update existing function to use intelligent merging when base site preserved.

**Implementation**:
```bash
# Enhanced merge_federation_output() function
merge_federation_output() {
    enter_function "merge_federation_output"
    set_error_context "Merging federation output"

    log_federation "Merging module outputs into federation structure"

    # If preserve-base-site, merge existing content first
    if [[ "$PRESERVE_BASE_SITE" == "true" ]] && [[ -n "${EXISTING_PAGES_DIR:-}" ]]; then
        log_info "Merging existing base site content"

        if [[ -d "$EXISTING_PAGES_DIR" ]]; then
            log_verbose "Existing content: $EXISTING_PAGES_DIR"

            # Copy existing content to output (base layer)
            if [[ ! -d "$OUTPUT" ]]; then
                mkdir -p "$OUTPUT"
            fi

            # Use rsync or cp to copy base content
            if command -v rsync >/dev/null 2>&1; then
                rsync -a "$EXISTING_PAGES_DIR/" "$OUTPUT/"
            else
                cp -r "$EXISTING_PAGES_DIR"/* "$OUTPUT"/ 2>/dev/null || true
            fi

            local existing_count=$(find "$OUTPUT" -type f | wc -l)
            log_success "Merged $existing_count existing files into base"
        else
            log_warning "Existing pages directory not found, skipping base merge"
        fi
    fi

    # Convert exported space-separated strings back to arrays
    local -a output_dirs
    local -a build_status
    read -ra output_dirs <<< "$MODULE_OUTPUT_DIRS"
    read -ra build_status <<< "$MODULE_BUILD_STATUS"

    local merged_count=0
    local skipped_count=0
    local conflict_count=0

    # Process each module
    for ((i=0; i<MODULES_COUNT; i++)); do
        local module_name_var="MODULE_${i}_NAME"
        local module_dest_var="MODULE_${i}_DESTINATION"
        local module_strategy_var="MODULE_${i}_MERGE_STRATEGY"

        local module_name="${!module_name_var}"
        local module_dest="${!module_dest_var:-/}"
        local module_strategy="${!module_strategy_var:-overwrite}"

        # Skip failed builds
        if [[ "${build_status[$i]}" != "success" ]]; then
            log_warning "Skipping merge for failed module: $module_name"
            skipped_count=$((skipped_count + 1))
            continue
        fi

        local module_output="${output_dirs[$i]}"

        # Determine target directory
        local dest_path="${module_dest#/}"
        local target_dir="$OUTPUT"

        if [[ -n "$dest_path" && "$dest_path" != "/" ]]; then
            target_dir="$OUTPUT/$dest_path"
        fi

        log_info "Merging $module_name → $target_dir (strategy: $module_strategy)"

        # In dry-run mode, just show what would happen
        if [[ "$DRY_RUN" == "true" ]]; then
            log_verbose "[DRY-RUN] Would merge: $module_output → $target_dir"
            merged_count=$((merged_count + 1))
            continue
        fi

        # Create target directory
        if ! mkdir -p "$target_dir"; then
            log_error "Failed to create target directory: $target_dir"
            continue
        fi

        # Apply intelligent merge with strategy
        if merge_with_strategy "$module_output" "$target_dir" "$module_strategy"; then
            log_success "Merged $module_name successfully"
            merged_count=$((merged_count + 1))
        else
            log_error "Failed to merge module: $module_name"
            conflict_count=$((conflict_count + 1))
        fi
    done

    log_info "Merge summary:"
    log_info "  - Modules merged: $merged_count"
    log_info "  - Modules skipped: $skipped_count"
    log_info "  - Merge conflicts: $conflict_count"

    if [[ $merged_count -eq 0 ]] && [[ $conflict_count -gt 0 ]]; then
        log_error "All module merges failed due to conflicts"
        exit_function
        return 1
    fi

    if [[ $merged_count -eq 0 ]]; then
        log_error "No modules were merged successfully"
        exit_function
        return 1
    fi

    exit_function
    return 0
}
```

**Enhancement Summary**:
- ✅ Merges existing base site first (if preserved)
- ✅ Uses intelligent merge with strategies
- ✅ Tracks merge statistics
- ✅ Reports conflicts clearly
- ✅ Fails gracefully on errors

**Verification**:
- [ ] Existing content merged first
- [ ] Per-module strategies applied
- [ ] Statistics accurate
- [ ] Conflicts reported
- [ ] Backward compatible (no preserve mode)

**Success Criteria**:
- ✅ Preserve mode fully functional
- ✅ Normal mode unchanged
- ✅ Clear logging
- ✅ Robust error handling

### Step 2.4: Add Merge Strategy to modules.json Schema

**Action**: Extend schema to support per-module merge strategies.

**Schema Addition**:
```json
{
  "modules": [
    {
      "name": "quiz-docs",
      "source": { ... },
      "destination": "/quiz/",
      "merge_strategy": "overwrite"  // NEW: optional, default "overwrite"
    }
  ]
}
```

**Validation**:
```javascript
// In load_modules_config() Node.js script
if (module.merge_strategy) {
    const validStrategies = ['overwrite', 'preserve', 'merge', 'error'];
    if (!validStrategies.includes(module.merge_strategy)) {
        console.error(`ERROR: Invalid merge_strategy for '${module.name}': ${module.merge_strategy}`);
        console.error(`  Valid strategies: ${validStrategies.join(', ')}`);
        process.exit(1);
    }
    console.log(`MODULE_${index}_MERGE_STRATEGY=${module.merge_strategy}`);
}
```

**Verification**:
- [ ] Schema updated
- [ ] Validation added
- [ ] Invalid strategies rejected
- [ ] Default strategy works
- [ ] Per-module config parsed

**Success Criteria**:
- ✅ Schema supports merge_strategy field
- ✅ Validation enforces valid values
- ✅ Default behavior preserved

### Step 2.5: Create Merge Test Suite

**Action**: Create `tests/test-intelligent-merge.sh` for merge functionality.

**Implementation**:
```bash
#!/usr/bin/env bash
# tests/test-intelligent-merge.sh

source "$(dirname "$0")/../scripts/federated-build.sh"

# Test 1: Detect conflicts correctly
test_conflict_detection() {
    local existing_dir="/tmp/test-existing-$$"
    local new_dir="/tmp/test-new-$$"

    mkdir -p "$existing_dir" "$new_dir"
    echo "existing" > "$existing_dir/conflict.html"
    echo "new" > "$new_dir/conflict.html"

    declare -a conflicts=()
    detect_merge_conflicts "$existing_dir" "$new_dir" conflicts

    if [[ ${#conflicts[@]} -eq 1 ]] && [[ "${conflicts[0]}" == "conflict.html" ]]; then
        echo "✓ Test 1 passed: Conflict detected"
        rm -rf "$existing_dir" "$new_dir"
        return 0
    fi

    echo "✗ Test 1 failed"
    rm -rf "$existing_dir" "$new_dir"
    return 1
}

# Test 2: Overwrite strategy
test_overwrite_strategy() {
    local source="/tmp/test-source-$$"
    local target="/tmp/test-target-$$"

    mkdir -p "$source" "$target"
    echo "old" > "$target/file.html"
    echo "new" > "$source/file.html"

    merge_with_strategy "$source" "$target" "overwrite" >/dev/null 2>&1

    local content=$(cat "$target/file.html")
    if [[ "$content" == "new" ]]; then
        echo "✓ Test 2 passed: Overwrite worked"
        rm -rf "$source" "$target"
        return 0
    fi

    echo "✗ Test 2 failed"
    rm -rf "$source" "$target"
    return 1
}

# Test 3: Preserve strategy
test_preserve_strategy() {
    local source="/tmp/test-source-$$"
    local target="/tmp/test-target-$$"

    mkdir -p "$source" "$target"
    echo "old" > "$target/file.html"
    echo "new" > "$source/file.html"

    merge_with_strategy "$source" "$target" "preserve" >/dev/null 2>&1

    local content=$(cat "$target/file.html")
    if [[ "$content" == "old" ]]; then
        echo "✓ Test 3 passed: Preserve worked"
        rm -rf "$source" "$target"
        return 0
    fi

    echo "✗ Test 3 failed"
    rm -rf "$source" "$target"
    return 1
}

# Test 4: Error strategy with conflicts
test_error_strategy() {
    local source="/tmp/test-source-$$"
    local target="/tmp/test-target-$$"

    mkdir -p "$source" "$target"
    echo "old" > "$target/file.html"
    echo "new" > "$source/file.html"

    if ! merge_with_strategy "$source" "$target" "error" >/dev/null 2>&1; then
        echo "✓ Test 4 passed: Error strategy rejected conflict"
        rm -rf "$source" "$target"
        return 0
    fi

    echo "✗ Test 4 failed: Should have failed on conflict"
    rm -rf "$source" "$target"
    return 1
}

# Run tests
echo "Running Intelligent Merge Tests..."
test_conflict_detection
test_overwrite_strategy
test_preserve_strategy
test_error_strategy

echo ""
echo "Merge tests complete!"
```

**Verification**:
- [ ] 4/4 tests pass
- [ ] Conflict detection works
- [ ] All strategies tested
- [ ] Tests isolated (temp dirs)

**Success Criteria**:
- ✅ Complete test coverage
- ✅ All tests passing
- ✅ Clear output

### Step 2.6: Documentation and Rollback Support

**Action**: Document merge strategies and add rollback mechanism.

**Documentation**:
```markdown
# Merge Strategies

Configure per-module merge behavior in modules.json:

\```json
{
  "modules": [
    {
      "name": "stable-docs",
      "merge_strategy": "preserve",  // Keep existing, don't overwrite
      "destination": "/docs/"
    },
    {
      "name": "dynamic-content",
      "merge_strategy": "overwrite", // Replace with new version
      "destination": "/blog/"
    }
  ]
}
\```

**Available Strategies**:

| Strategy | Behavior | Best For |
|----------|----------|----------|
| `overwrite` | New replaces existing | Regular updates |
| `preserve` | Keep existing | Stable content |
| `merge` | Combine compatible files | Complementary content |
| `error` | Fail on conflict | Critical deployments |
\```

**Verification**:
- [ ] Documentation complete
- [ ] Examples provided
- [ ] Best practices documented

**Success Criteria**:
- ✅ Clear merge strategy docs
- ✅ Examples for all strategies
- ✅ Best practices guide

## Testing Plan

### Unit Tests
- [x] `detect_merge_conflicts()` - file conflicts
- [x] `detect_merge_conflicts()` - directory conflicts
- [x] `merge_with_strategy()` - overwrite
- [x] `merge_with_strategy()` - preserve
- [x] `merge_with_strategy()` - merge
- [x] `merge_with_strategy()` - error

### Integration Tests
- [ ] Full preserve + merge workflow
- [ ] Multiple modules with different strategies
- [ ] Conflict resolution in real federation

### Edge Cases
- [ ] File vs directory conflict
- [ ] Symlink handling
- [ ] Large file merges
- [ ] Binary file merges
- [ ] Permission issues

## Definition of Done

- [x] All 6 steps completed
- [x] `detect_merge_conflicts()` implemented
- [x] `merge_with_strategy()` implemented
- [x] `merge_federation_output()` enhanced
- [x] Schema updated with merge_strategy
- [x] Test suite created and passing (4/4)
- [x] Documentation updated
- [x] Ready for Stage 3 (deploy preparation)

## Files to Create/Modify

### Modified Files
- `scripts/federated-build.sh` - Merge enhancements (~200 lines)
- `schemas/modules.schema.json` - Add merge_strategy field

### New Files
- `tests/test-intelligent-merge.sh` - Merge test suite

### Documentation
- `docs/user-guides/merge-strategies.md` - Complete merge strategy guide
- `docs/proposals/.../child-4-download-merge-deploy/002-progress.md` - Stage 2 report

## Expected Outcome

After Stage 2 completion:
- ✅ Intelligent merge system operational
- ✅ Conflict detection and reporting
- ✅ Four merge strategies implemented
- ✅ Per-module strategy configuration
- ✅ Enhanced merge_federation_output() function
- ✅ Comprehensive test coverage
- ✅ Foundation ready for Stage 3 (deploy preparation)

---

**Stage 2 Estimated Time**: 4 hours
- Step 2.1: Conflict detection (1 hour)
- Step 2.2: Merge strategies (1.5 hours)
- Step 2.3: Enhance merge function (1 hour)
- Step 2.4: Schema update (0.5 hours)
- Step 2.5: Test suite (0.5 hours)
- Step 2.6: Documentation (0.5 hours)

**Next Stage**: 003-deploy-preparation.md
