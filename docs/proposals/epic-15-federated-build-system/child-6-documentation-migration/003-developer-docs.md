# Stage 3: Developer Documentation

**Child Issue**: #21 - Documentation & Migration
**Stage**: 3 of 4
**Priority**: MEDIUM (README > User guides > Developer docs > Migration)
**Estimated Duration**: 4 hours
**Dependencies**: Stage 2 (User Guides)

---

## 🎯 Objective

Create comprehensive developer documentation for the federated build system, including architecture overview, API reference, and contribution guidelines for federation features.

---

## 📋 Tasks Breakdown

### Task 3.1: Create Federation Architecture Document (1.5 hours)

**Goal**: Document technical architecture and design decisions

**Actions**:
1. Create new file: `docs/content/developer-docs/federation-architecture.md`
2. Document Layer 1 vs Layer 2 architecture
3. Explain federation workflows (3 strategies)
4. Document design decisions and rationale
5. Add system diagrams (ASCII or mermaid)

**Content to Include**:

**Section 1: Overview**:
```markdown
# Federation Architecture

## Introduction
The federated build system (Layer 2) orchestrates multiple Hugo sites from different repositories, merging them into a unified GitHub Pages deployment.

## Layer Architecture
- **Layer 1**: Single-site builds (build.sh) - 78 tests
- **Layer 2**: Multi-module federation (federated-build.sh) - 82 tests
- **Integration**: Layer 1+2 interaction - 14 tests

Layer 2 builds upon Layer 1, using it for individual module builds before merging.
```

**Section 2: Federation Workflows**:
```markdown
## Three Federation Strategies

### 1. download-merge-deploy (Default)
**Use Case**: Pre-built modules from GitHub Releases

Workflow:
1. Download built sites from module releases
2. Merge content intelligently
3. Deploy merged output

Best for: Production deployments, CI/CD pipelines

### 2. merge-and-build
**Use Case**: Build all modules from source

Workflow:
1. Clone module repositories
2. Build each module using Layer 1 (build.sh)
3. Merge built outputs
4. Deploy merged result

Best for: Development, testing, full rebuilds

### 3. preserve-base-site
**Use Case**: Merge modules into existing base site

Workflow:
1. Keep base site intact
2. Merge additional modules
3. Deploy combined site

Best for: Adding content to existing site
```

**Section 3: Key Components**:
```markdown
## Core Components

### federated-build.sh
Main orchestration script (1,200 lines)
- Configuration parsing
- Module validation
- Source fetching (Git/local/GitHub Releases)
- Intelligent merging
- CSS path rewriting
- Conflict resolution

### modules.schema.json
JSON Schema for configuration validation
- Base site configuration
- Module definitions
- Strategy selection
- Source specifications (oneOf: local/remote)

### Intelligent Merge System
- Content deduplication
- CSS path detection and rewriting
- Conflict detection and resolution
- YAML front matter preservation
```

**Section 4: Design Decisions**:
```markdown
## Design Rationale

### Why Layer 2?
- Layer 1 proven and stable (78 tests, production-ready)
- Federation as enhancement, not replacement
- Clear separation of concerns
- Independent testing and development

### Why Three Strategies?
- Different use cases have different needs
- download-merge-deploy: Fast, CI/CD-friendly
- merge-and-build: Complete control, development
- preserve-base-site: Incremental enhancement

### Why Intelligent Merge?
- Naive rsync causes path conflicts
- CSS references break with simple copy
- Content duplication wastes space
- Conflicts need resolution, not silent overwrites

### Why JSON Schema Validation?
- Catch configuration errors early
- Self-documenting configuration format
- IDE support via schema
- Extensible for future features
```

**Section 5: Testing Architecture**:
```markdown
## Testing Strategy

### Test Layers
1. **Unit Tests**: 45 BATS tests for individual functions
2. **Shell Script Tests**: 37 tests for core functionality
3. **Integration Tests**: 14 E2E tests for real scenarios
4. **Performance Tests**: 5 benchmarks for regression detection

### Coverage
- 140 total tests (100% passing)
- 28 functions covered in federated-build.sh
- All 3 strategies tested
- Error recovery tested
- Performance baselines established

### Test Fixtures
- 3 JSON configs (simple, advanced, infotech)
- 2 mock repositories
- Comprehensive error scenarios
```

**Validation**:
- Architecture is clear and comprehensive
- Design decisions are well-justified
- Diagrams illustrate complex workflows
- Testing strategy is explained

**Estimated Lines**: ~400 lines

---

### Task 3.2: Create Federation API Reference (1.5 hours)

**Goal**: Document all 28 functions in federated-build.sh

**Actions**:
1. Create new file: `docs/content/developer-docs/federation-api-reference.md`
2. Document all 28 functions from coverage matrix
3. Include function signatures, parameters, return values, examples
4. Group by category (config, validation, merge, etc.)
5. Add usage examples for key functions

**Content to Include**:

**Structure**:
```markdown
# Federation API Reference

## Overview
Complete reference for all functions in `scripts/federated-build.sh`.

## Function Categories
1. Configuration Management (5 functions)
2. Validation (6 functions)
3. Source Fetching (4 functions)
4. Build & Merge (8 functions)
5. CSS Rewriting (3 functions)
6. Utilities (2 functions)

---

## Configuration Management

### parse_federation_config()
**Description**: Parse modules.json configuration file

**Parameters**:
- `$1` - Path to JSON configuration file

**Returns**:
- `0` - Success, config parsed and validated
- `1` - Parse error or validation failure

**Global Variables Set**:
- `BASE_SITE_*` - Base site configuration
- `MODULES` - Array of module configurations
- `STRATEGY` - Selected federation strategy

**Example**:
```bash
parse_federation_config "modules.json" || {
    log_error "Configuration parsing failed"
    exit 1
}
```

**Tests**:
- federated-config.bats: "parse_federation_config handles valid config"
- federated-config.bats: "parse_federation_config rejects invalid config"

---

### get_module_config()
**Description**: Extract configuration for specific module

**Parameters**:
- `$1` - Module name/ID

**Returns**:
- `0` - Success, module config printed to stdout
- `1` - Module not found

**Output**: JSON object with module configuration

**Example**:
```bash
config=$(get_module_config "module-api") || {
    log_error "Module 'module-api' not found"
    exit 1
}
```

**Tests**:
- federated-config.bats: "get_module_config returns correct config"
```

**Pattern for All 28 Functions**:
Each function documented with:
1. Description (one-line summary)
2. Parameters (with types and descriptions)
3. Returns (exit codes and meanings)
4. Global variables (read/written)
5. Output (stdout/stderr behavior)
6. Example usage (practical code snippet)
7. Related tests (links to test files)

**Function List** (from coverage-matrix-federation.md):
1. parse_federation_config
2. get_module_config
3. validate_federation_config
4. validate_module_sources
5. validate_oneOf_constraints
6. check_module_compatibility
7. fetch_module_source
8. clone_git_repository
9. download_github_release
10. copy_local_module
11. build_module
12. merge_module_content
13. intelligent_merge
14. detect_css_paths
15. rewrite_css_paths
16. resolve_merge_conflicts
17. validate_merged_output
18. setup_federation_environment
19. cleanup_federation_temp
20. log_federation_progress
21. handle_federation_errors
22. run_federation_hooks
23. generate_federation_report
24. check_federation_prerequisites
25. parse_command_line_args
26. display_federation_help
27. run_federation_dry_run
28. main (federation orchestration)

**Validation**:
- All 28 functions documented
- Examples are runnable
- Test references are accurate
- Grouping is logical

**Estimated Lines**: ~700 lines (25 lines average per function)

---

### Task 3.3: Update Contributing Guide (1 hour)

**Goal**: Add federation-specific contribution guidelines

**Actions**:
1. Read existing `docs/content/contributing/_index.md`
2. Add "Contributing to Federation" section
3. Explain Layer 1 vs Layer 2 contribution workflow
4. Document testing requirements for federation PRs
5. Add links to federation testing guide
6. Verify workflow links are correct

**Content to Add**:

**Section: Contributing to Federation (Layer 2)**:
```markdown
## Contributing to Federation Features

### Understanding Layers
The project uses a layered architecture:
- **Layer 1**: Single-site builds (`build.sh`) - Stable, production-ready
- **Layer 2**: Multi-module federation (`federated-build.sh`) - Enhancement layer

When contributing federation features:
1. Layer 2 must not modify Layer 1
2. Layer 2 uses Layer 1 for individual module builds
3. Test both layers independently and together

### Federation Development Workflow

#### 1. Setup Development Environment
```bash
# Clone repository
git clone https://github.com/info-tech-io/hugo-templates.git
cd hugo-templates

# Create feature branch from epic branch
git checkout epic/federated-build-system
git checkout -b feature/federation-your-feature

# Install dependencies
npm install
```

#### 2. Make Changes
Follow the project structure:
- Federation code: `scripts/federated-build.sh`
- Schema: `schemas/modules.schema.json`
- Tests: `tests/bash/unit/federated-*.bats`
- Integration tests: `tests/bash/integration/federation-e2e.bats`
- Documentation: `docs/content/*/federation-*.md`

#### 3. Write Tests FIRST
**CRITICAL**: Federation features require comprehensive testing.

For new functions:
1. Add unit test in `tests/bash/unit/federated-*.bats`
2. Run test, watch it fail
3. Implement function
4. Run test, verify pass
5. Add integration test if needed

```bash
# Run federation tests
./tests/run-federation-tests.sh --layer unit

# Run all tests
./tests/run-federation-tests.sh --layer all
```

#### 4. Update Documentation
For user-facing changes:
- Update `docs/content/user-guides/federated-builds.md`
- Add examples if needed
- Update tutorials if workflow changes

For technical changes:
- Update `docs/content/developer-docs/federation-architecture.md`
- Update `docs/content/developer-docs/federation-api-reference.md`
- Add to coverage matrix: `docs/content/developer-docs/testing/coverage-matrix-federation.md`

#### 5. Run Full Test Suite
```bash
# Layer 1 tests (must not break)
./scripts/test-bash.sh

# Layer 2 unit tests
./tests/run-federation-tests.sh --layer unit

# Integration tests
./tests/run-federation-tests.sh --layer integration

# All federation tests
./tests/run-federation-tests.sh --layer all

# Performance benchmarks
./tests/run-federation-tests.sh --layer performance
```

#### 6. Create Pull Request
```bash
# Commit changes
git add .
git commit -m "feat: add federation feature X

Description of changes...

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to origin
git push origin feature/federation-your-feature

# Create PR to epic branch
gh pr create --base epic/federated-build-system \
  --title "feat: add federation feature X" \
  --body "## Summary

  Description...

  ## Testing
  - [ ] Unit tests: X passing
  - [ ] Integration tests: Y passing
  - [ ] Documentation updated

  ## Related
  - Child Issue: #21
  - Epic: #15"
```

### Testing Requirements for Federation PRs

All federation PRs must include:
1. ✅ Unit tests for new functions (BATS)
2. ✅ Integration test if user-facing
3. ✅ All 140 existing tests still passing
4. ✅ Documentation updates
5. ✅ Coverage matrix updated

**PR Checklist**:
- [ ] Tests written before implementation
- [ ] All tests passing locally
- [ ] Documentation updated
- [ ] No Layer 1 modifications (unless intentional)
- [ ] Conventional commit format used
- [ ] PR targets correct branch (epic/federated-build-system)

### Federation Testing Guide

See comprehensive testing documentation:
- [Testing Guide](../developer-docs/testing/federation-testing.md) - Overview
- [Test Inventory](../developer-docs/testing/test-inventory.md) - All 140 tests
- [Coverage Matrix](../developer-docs/testing/coverage-matrix-federation.md) - 28 functions
- [Testing Guidelines](../developer-docs/testing/guidelines.md) - Patterns G & H
```

**Validation**:
- Section integrates with existing contributing guide
- Workflow is clear and actionable
- Testing requirements are specific
- Links are correct

**Estimated Lines**: ~150 lines added

---

## 📁 Files Modified/Created

### New Files (Created)

#### docs/content/developer-docs/federation-architecture.md
**Type**: CREATE (new file)
**Purpose**: Technical architecture overview
**Content**: Layer architecture, workflows, design decisions, testing strategy
**Lines**: ~400 lines

#### docs/content/developer-docs/federation-api-reference.md
**Type**: CREATE (new file)
**Purpose**: Complete API documentation
**Content**: All 28 functions with signatures, examples, tests
**Lines**: ~700 lines

### Modified Files (Updated)

#### docs/content/contributing/_index.md
**Type**: UPDATE (existing file)
**Changes**:
- Add "Contributing to Federation" section
- Add federation development workflow
- Add testing requirements
- Add PR checklist
**Lines Added**: ~150 lines

**Total New Content**: ~1,250 lines

---

## ✅ Success Criteria

- [ ] federation-architecture.md created with 400+ lines
- [ ] All architectural concepts clearly explained
- [ ] Layer 1 vs Layer 2 distinction is clear
- [ ] Three federation strategies documented
- [ ] Design decisions justified
- [ ] federation-api-reference.md created with 700+ lines
- [ ] All 28 functions documented
- [ ] Each function has signature, example, tests
- [ ] Functions grouped logically
- [ ] contributing/_index.md updated with federation section
- [ ] Federation workflow documented
- [ ] Testing requirements clear
- [ ] PR checklist included
- [ ] All links functional

---

## 🧪 Validation Commands

### Check Architecture Document
```bash
wc -l docs/content/developer-docs/federation-architecture.md
# Should be ~400 lines

grep -i "layer 1\|layer 2" docs/content/developer-docs/federation-architecture.md | wc -l
# Should have multiple references

grep "download-merge-deploy\|merge-and-build\|preserve-base-site" docs/content/developer-docs/federation-architecture.md | wc -l
# Should be >= 3 (all strategies mentioned)
```

### Check API Reference
```bash
wc -l docs/content/developer-docs/federation-api-reference.md
# Should be ~700 lines

grep "^### " docs/content/developer-docs/federation-api-reference.md | wc -l
# Should be 28 (one H3 per function)

grep "**Example**:" docs/content/developer-docs/federation-api-reference.md | wc -l
# Should be 28 (one example per function)
```

### Check Contributing Update
```bash
grep -A 10 "Contributing to Federation" docs/content/contributing/_index.md
# Should show new section

grep "run-federation-tests.sh" docs/content/contributing/_index.md | wc -l
# Should have references to test runner
```

### Validate Links
```bash
# Check all documentation links
grep -r "federation-architecture.md\|federation-api-reference.md" docs/content/ | \
  grep -v ".md:.*\.md" | \
  while read line; do
    echo "✅ Reference found: $line"
  done
```

---

## 📊 Deliverables

1. ✅ federation-architecture.md (~400 lines)
   - Layer architecture explained
   - Three strategies documented
   - Design decisions justified
   - Testing strategy covered

2. ✅ federation-api-reference.md (~700 lines)
   - 28 functions documented
   - Signatures, parameters, returns
   - Practical examples
   - Test references

3. ✅ contributing/_index.md updated (~150 lines added)
   - Federation workflow
   - Testing requirements
   - PR checklist
   - Layer separation guidelines

**Total**: 2 new files, 1 updated file, ~1,250 lines

---

## 🔄 Commit Strategy

**Commit 1: Architecture Document**
```bash
git add docs/content/developer-docs/federation-architecture.md
git commit -m "docs: add federation architecture document

Complete technical architecture overview:
- Layer 1 vs Layer 2 architecture
- Three federation strategies explained
- Design decisions and rationale
- Testing architecture documented

Target audience: Developers extending federation system
Lines: ~400

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Commit 2: API Reference**
```bash
git add docs/content/developer-docs/federation-api-reference.md
git commit -m "docs: add federation API reference

Complete API documentation for federated-build.sh:
- All 28 functions documented
- Signatures, parameters, return values
- Practical usage examples
- Test coverage references

Grouped by category: config, validation, fetch, merge, utils
Lines: ~700

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Commit 3: Contributing Guide Update**
```bash
git add docs/content/contributing/_index.md
git commit -m "docs: add federation contribution guidelines

Added federation-specific contribution section:
- Layer 1 vs Layer 2 workflow
- Federation development workflow
- Testing requirements (unit + integration)
- PR checklist for federation features

Lines added: ~150

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## ⏱️ Time Tracking

| Task | Estimated | Actual | Notes |
|------|-----------|--------|-------|
| 3.1: Architecture Doc | 1.5 hours | | |
| 3.2: API Reference | 1.5 hours | | |
| 3.3: Contributing Update | 1 hour | | |
| **Total** | **4 hours** | | |

---

## 📝 Notes

### Key Points
- Architecture doc explains "why" not just "how"
- API reference is comprehensive reference, not tutorial
- Contributing guide focuses on federation-specific workflow
- All docs assume reader has basic Hugo/bash knowledge

### What NOT to Do
- Don't duplicate user guide content in architecture doc
- Don't add beginner bash tutorials to API reference
- Don't modify existing contributing sections (only add)
- Don't document Layer 1 functions (only Layer 2)

### Dependencies for Next Stage
- These docs will be linked from README (Stage 1)
- API reference will be used by advanced users
- Architecture doc will be referenced in user guides
- Contributing guide will be used by new contributors

### Related Documentation
- federation-testing.md (already exists from Child #20)
- coverage-matrix-federation.md (already exists from Child #20)
- test-inventory.md (already exists, updated in Child #20)

---

**Status**: Ready for implementation
**Previous Stage**: 002-user-guides.md
**Next Stage**: 004-migration-resources.md
**Updated**: 2025-10-19
