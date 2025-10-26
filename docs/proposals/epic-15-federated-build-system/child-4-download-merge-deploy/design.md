# Design: Child #19 - Download-Merge-Deploy Logic

**Issue**: #19
**Epic**: #15 - Federated Build System
**Status**: 🚀 Ready for Implementation
**Estimated Duration**: 1.5 days (~12 hours)
**Dependencies**: Child #16, #17, #18

## Problem Statement

Implement the core Download-Merge-Deploy pattern for incremental federated builds, enabling preservation of existing content while adding new module content. This allows partial federation updates without requiring full rebuilds of all modules.

### Current Limitation

Without Download-Merge-Deploy:
- Adding/updating a single module requires rebuilding entire federation
- Cannot preserve existing stable content
- Manual coordination needed for multi-module updates
- No incremental update capability

### Business Need

**Use Case**: InfoTech.io Documentation
- Current: Corporate site + Quiz docs deployed
- Need: Add Hugo Templates docs
- Problem: Don't want to rebuild corporate + quiz
- Solution: Download existing, build only hugo-templates, merge all

## Technical Solution

### Download-Merge-Deploy Pattern

Three-phase approach for incremental federation updates:

1. **Download**: Fetch existing GitHub Pages content (if `--preserve-base-site` enabled)
2. **Merge**: Combine existing content with new module builds using intelligent strategies
3. **Deploy**: Validate and prepare deployment-ready artifacts

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Stage 1: Download (--preserve-base-site)                │
│  ┌───────────────────────────────────────────────────┐  │
│  │ download_existing_pages(baseURL, output_dir)      │  │
│  │ - wget-based mirroring                            │  │
│  │ - Preserve directory structure                    │  │
│  │ - Download all assets (HTML, CSS, JS, images)    │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│  Stage 2: Intelligent Merge                              │
│  ┌───────────────────────────────────────────────────┐  │
│  │ detect_merge_conflicts(existing, new)            │  │
│  │ merge_with_strategy(source, target, strategy)    │  │
│  │ - overwrite: New replaces existing               │  │
│  │ - preserve: Keep existing, skip new              │  │
│  │ - merge: Combine compatible content              │  │
│  │ - error: Fail on any conflict                    │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│  Stage 3: Deploy Preparation                             │
│  ┌───────────────────────────────────────────────────┐  │
│  │ validate_federation_output() - Enhanced          │  │
│  │ generate_deployment_artifacts()                  │  │
│  │ - SHA256 checksums                               │  │
│  │ - Deployment metadata                            │  │
│  │ verify_deployment_ready()                        │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Core Logic Flow
```bash
# Stage 1: Download (optional)
IF --preserve-base-site:
    download_existing_pages(FEDERATION_BASE_URL) → temp/existing/
    export EXISTING_PAGES_DIR

# Stage 2: Build & Merge
FOR each module in modules.json:
    download_module_source() → temp/module-X/
    build_module() → temp/output-X/
    apply_css_path_resolution()

# Stage 2: Merge with existing
IF --preserve-base-site:
    merge existing content to output (base layer)

FOR each module:
    detect_merge_conflicts(output, module_output)
    merge_with_strategy(module_output, output, module.merge_strategy)

# Stage 3: Deploy Preparation
validate_federation_output()
generate_deployment_artifacts()
verify_deployment_ready()

# Ready for deployment
```

## Implementation Stages

### Stage 1: Content Download System (4 hours)

**Objective**: Download existing GitHub Pages content via wget

**Deliverables**:
- `download_existing_pages(baseURL, output_dir)` function
- Integration with `--preserve-base-site` flag
- Progress reporting and error handling
- Edge case handling (404, timeout, auth)
- Test suite: `tests/test-download-pages.sh`

**Key Features**:
- wget-based mirroring
- Directory structure preservation
- Asset downloading (HTML, CSS, JS, images)
- Authentication support
- Rate limiting handling

**Detailed Plan**: `001-download-existing-pages.md`

### Stage 2: Intelligent Merging (4 hours)

**Objective**: Conflict detection and resolution with merge strategies

**Deliverables**:
- `detect_merge_conflicts(existing, new)` function
- `merge_with_strategy(source, target, strategy)` function
- Enhanced `merge_federation_output()`
- Merge strategy schema field
- Test suite: `tests/test-intelligent-merge.sh`

**Merge Strategies**:
| Strategy | Behavior | Use Case |
|----------|----------|----------|
| `overwrite` | New replaces existing | Regular updates |
| `preserve` | Keep existing, skip new | Stable content protection |
| `merge` | Combine compatible content | Complementary updates |
| `error` | Fail on conflict | Critical deployments |

**Detailed Plan**: `002-intelligent-merging.md`

### Stage 3: Deploy Preparation (4 hours)

**Objective**: Validation, artifacts, and deployment readiness

**Deliverables**:
- Enhanced `validate_federation_output()` (3 phases)
- `generate_deployment_artifacts()` function
- Enhanced deployment manifest
- `verify_deployment_ready()` function
- Deployment guide documentation

**Validation Phases**:
1. Structure validation (directories, index files)
2. Content validation (HTML validity)
3. Asset path validation (CSS/JS paths correct)

**Deployment Artifacts**:
- `checksums.sha256` - File integrity verification
- `deployment.json` - Build metadata and statistics
- Enhanced `federation-manifest.json`

**Detailed Plan**: `003-deploy-preparation.md`

## Key Functions

### Download Phase
```bash
download_existing_pages(baseURL, output_dir)
# Downloads GitHub Pages content with wget mirroring
# Returns: 0 on success, 1 on failure
```

### Merge Phase
```bash
detect_merge_conflicts(existing_dir, new_dir, conflicts_array)
# Detects file/directory conflicts
# Returns: 0 if no conflicts, 1 if conflicts found

merge_with_strategy(source_dir, target_dir, strategy)
# Applies merge strategy (overwrite|preserve|merge|error)
# Returns: 0 on success, 1 on failure
```

### Deploy Phase
```bash
generate_deployment_artifacts()
# Creates checksums and metadata
# Returns: 0 on success, 1 on failure

verify_deployment_ready()
# Runs pre-deployment checks
# Returns: 0 if ready, 1 if not ready
```

## Integration Points

### With Existing Systems

**federated-build.sh (Child #16)**:
- Uses existing orchestration workflow
- Adds download before builds
- Enhances merge after builds
- Adds validation after merge

**modules.json (Child #17)**:
- New field: `merge_strategy` (per module)
- Uses existing `federation.baseURL` for downloads
- No breaking schema changes

**CSS Resolution (Child #18)**:
- Merge happens after CSS path resolution
- Downloaded content may have incorrect paths (fixed during build)
- New modules have paths fixed before merge

### Workflow Integration

```bash
main() {
    parse_arguments()
    load_modules_config()
    validate_configuration()

    # Stage 1: Download (NEW - if --preserve-base-site)
    if [[ "$PRESERVE_BASE_SITE" == "true" ]]; then
        download_existing_pages()
    fi

    # Stage 2: Build (existing)
    orchestrate_builds()

    # Stage 2.5: Merge (ENHANCED)
    merge_federation_output()  # Now supports intelligent merge

    # Stage 3: Validation (ENHANCED)
    validate_federation_output()

    # Stage 3.5: Deploy Prep (NEW)
    generate_deployment_artifacts()
    verify_deployment_ready()

    generate_build_report()
}
```

## Success Criteria

**Technical**:
- ✅ Downloads existing GitHub Pages content
- ✅ 4 merge strategies implemented and tested
- ✅ Conflict detection accurate
- ✅ 3-phase validation comprehensive
- ✅ Deployment artifacts generated
- ✅ Pre-deployment verification functional

**Operational**:
- ✅ Incremental updates work (add single module)
- ✅ `--preserve-base-site` flag functional
- ✅ Backward compatible (flag optional)
- ✅ No breaking changes
- ✅ Clear error messages

**Quality**:
- ✅ Test suites passing (3 test files)
- ✅ Documentation complete
- ✅ Edge cases handled
- ✅ Performance acceptable (< 5min for typical federation)

## Timeline

| Stage | Duration | Dependencies | Status |
|-------|----------|--------------|--------|
| Stage 1: Download | 4 hours | None | ⬜ Not Started |
| Stage 2: Merge | 4 hours | Stage 1 | ⬜ Not Started |
| Stage 3: Deploy Prep | 4 hours | Stages 1 & 2 | ⬜ Not Started |

**Total**: 12 hours (~1.5 days)

## Risk Mitigation

**Risk 1: wget Not Available**
- Mitigation: Check availability, provide clear error
- Fallback: Manual download instructions

**Risk 2: Large Site Downloads**
- Mitigation: Timeout configuration, progress reporting
- Fallback: Local download option

**Risk 3: Merge Conflicts**
- Mitigation: Conflict detection before merge, strategy selection
- Fallback: Error strategy (fail safely)

**Risk 4: Incomplete Validation**
- Mitigation: 3-phase comprehensive validation
- Fallback: Manual verification guide

## Files to Create/Modify

### New Files
- `tests/test-download-pages.sh` - Download tests (3 tests)
- `tests/test-intelligent-merge.sh` - Merge tests (4 tests)
- `docs/user-guides/merge-strategies.md` - Merge guide
- `docs/user-guides/deploying-federation.md` - Deployment guide

### Modified Files
- `scripts/federated-build.sh` - Add ~600 lines
  - Stage 1: ~150 lines (download)
  - Stage 2: ~250 lines (merge enhancements)
  - Stage 3: ~200 lines (deploy prep)
- `schemas/modules.schema.json` - Add `merge_strategy` field
- `docs/user-guides/federated-builds.md` - Document `--preserve-base-site`

### Documentation Files
- All stage plans: `001-*.md`, `002-*.md`, `003-*.md` ✅
- All progress files: `001-progress.md`, `002-progress.md`, `003-progress.md` ✅
- This design document ✅
- Overall progress: `progress.md` ✅

## Conclusion

Child #19 completes the Download-Merge-Deploy pattern, enabling:
- **Incremental federation updates** without full rebuilds
- **Intelligent merging** with conflict detection and strategies
- **Deployment-ready artifacts** with comprehensive validation

This provides the final piece for production-ready federated builds, completing Epic #15's core functionality.

**Status**: 🚀 **READY FOR IMPLEMENTATION** - All planning complete

---

**Version**: 2.0 (Enhanced)
**Last Updated**: October 13, 2025
**Next Action**: Create feature branch and begin Stage 1