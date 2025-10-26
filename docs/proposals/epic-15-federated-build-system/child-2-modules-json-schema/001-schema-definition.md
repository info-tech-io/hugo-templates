# Stage 1: Schema Definition

## Objective
Create comprehensive JSON Schema for modules.json configuration file that defines federation and module configuration structure.

## Detailed Steps

### 1.1 Create JSON Schema file structure
**Action**: Create `schemas/modules.schema.json` with JSON Schema Draft-07 structure

**Implementation**:
- Set up JSON Schema metadata ($schema, $id, title, description)
- Define top-level schema structure (federation + modules)
- Add schema version for future compatibility

**Expected Outcome**: Basic JSON Schema file structure
**Estimated Time**: 30 minutes

### 1.2 Define federation configuration schema
**Action**: Define schema for `federation` object

**Required Fields**:
- `name` (string): Federation name
- `baseURL` (string, format: uri): Base URL for federation
- `strategy` (string, enum): Build strategy (download-merge-deploy)

**Optional Fields**:
- `build_settings` (object): Build configuration
  - `parallel` (boolean): Enable parallel builds
  - `cache_enabled` (boolean): Enable caching
  - `performance_tracking` (boolean): Enable performance monitoring
  - `max_parallel_builds` (integer): Maximum parallel builds

**Expected Outcome**: Complete federation schema definition
**Estimated Time**: 45 minutes

### 1.3 Define module configuration schema
**Action**: Define schema for items in `modules` array

**Required Fields**:
- `name` (string): Module identifier
- `source` (object): Source configuration
  - `repository` (string): Repository URL or "local"
  - `path` (string): Path within repository
  - `branch` (string): Git branch name
- `destination` (string): URL path destination
- `module_json` (string): Path to module.json file

**Optional Fields**:
- `css_path_prefix` (string): CSS path prefix for subdirectory deployment
- `overrides` (object): Module.json overrides
  - `baseURL` (string, format: uri)
  - `theme` (string)
  - `components` (array of strings)
- `build_options` (object): Per-module build options
  - `cache_enabled` (boolean)
  - `skip_on_error` (boolean)

**Expected Outcome**: Complete module schema definition
**Estimated Time**: 1 hour

### 1.4 Add schema validation rules
**Action**: Add validation constraints and patterns

**Validations**:
- `name` pattern: `^[a-z0-9-]+$` (lowercase, numbers, hyphens only)
- `destination` pattern: `^/` (must start with slash)
- `baseURL` must not end with slash
- `repository` pattern for GitHub URLs or "local"
- `branch` pattern: valid git branch names

**Constraints**:
- `modules` array: minItems=1
- `strategy` enum: ["download-merge-deploy", "preserve-base-site"]
- `max_parallel_builds`: minimum=1, maximum=10

**Expected Outcome**: Schema with comprehensive validation rules
**Estimated Time**: 45 minutes

### 1.5 Add schema examples and documentation
**Action**: Add example values and descriptions to schema

**Documentation**:
- Add `description` fields to all properties
- Add `examples` for complex objects
- Add `$comment` annotations for implementation notes
- Document default values

**Expected Outcome**: Well-documented, self-explanatory schema
**Estimated Time**: 30 minutes

### 1.6 Create comprehensive example files
**Action**: Create multiple example modules.json configurations

**Examples to Create**:
1. **docs/content/examples/modules-simple.json**: Minimal 2-module federation
2. **docs/content/examples/modules-infotech.json**: Full InfoTech.io federation (5 modules)
3. **docs/content/examples/modules-advanced.json**: Advanced features showcase

**Expected Outcome**: 3 example configurations covering all schema features
**Estimated Time**: 45 minutes

## Success Criteria
- [x] `schemas/modules.schema.json` exists and is valid JSON Schema
- [ ] Federation configuration fully defined with all required/optional fields
- [ ] Module configuration fully defined with all required/optional fields
- [ ] Validation rules enforce correct configuration format
- [ ] Schema is self-documenting with descriptions and examples
- [ ] 3 example configurations created and documented
- [ ] Schema validates all existing modules.json files (test-modules.json, etc.)

## Files Created
- `schemas/modules.schema.json` (new file)
- `docs/content/examples/modules-simple.json` (new example)
- `docs/content/examples/modules-infotech.json` (updated from existing)
- `docs/content/examples/modules-advanced.json` (new example)

## Files Modified
- None

## Testing Commands
```bash
# Validate schema itself is valid JSON Schema
npx ajv-cli compile -s schemas/modules.schema.json

# Validate example files against schema
npx ajv-cli validate -s schemas/modules.schema.json -d "docs/content/examples/modules-*.json"

# Test with existing configurations
npx ajv-cli validate -s schemas/modules.schema.json -d test-modules.json
```

## Definition of Done
- Schema file is valid JSON Schema Draft-07
- All required and optional fields are defined
- Validation rules enforce correct structure
- Schema passes self-validation
- All example files validate successfully
- Documentation is clear and comprehensive

---

**Status**: ⬜ Not Started
**Assigned**: TBD
**Due Date**: TBD

**Dependencies**: None (Child #16 complete provides context)

**Implementation Notes**:
- Follow JSON Schema Draft-07 specification
- Use strict validation patterns for security
- Document all fields thoroughly for future maintainability
- Examples should cover common use cases
