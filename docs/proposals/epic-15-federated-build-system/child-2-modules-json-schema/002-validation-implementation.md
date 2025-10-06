# Stage 2: Validation Implementation

## Objective
Implement schema validation in federated-build.sh using the JSON Schema definition, with comprehensive error reporting and testing.

## Detailed Steps

### 2.1 Enhance modules.json parser in federated-build.sh
**Action**: Update `load_modules_config()` function to use JSON Schema validation

**Implementation**:
- Keep existing Node.js inline script approach
- Add JSON Schema validation before parsing
- Load schema from `schemas/modules.schema.json`
- Provide structured error reporting

**Expected Outcome**: Parser validates against schema before processing
**Estimated Time**: 45 minutes

### 2.2 Implement comprehensive error reporting
**Action**: Add detailed validation error messages

**Error Categories**:
1. **Schema Validation Errors**
   - Missing required fields
   - Invalid field types
   - Pattern mismatches
   - Constraint violations

2. **Logical Validation Errors**
   - Duplicate module names
   - Destination path conflicts
   - Invalid repository URLs

3. **Runtime Validation Errors**
   - Source repository inaccessible
   - module.json file not found
   - Invalid file paths

**Error Message Format**:
```
❌ Validation Error: modules.json is invalid

Schema Errors:
  • Module "corporate-site": Missing required field "destination"
  • Module "quiz-docs": Invalid pattern for "name" (must be lowercase)
  • Federation: "baseURL" must be a valid URI

Please fix these errors and try again.
```

**Expected Outcome**: Clear, actionable error messages
**Estimated Time**: 1 hour

### 2.3 Add validation-only mode improvements
**Action**: Enhance `--validate-only` flag functionality

**Improvements**:
- Show detailed schema validation report
- Test all module source accessibility
- Check all module.json files exist
- Validate destination path uniqueness
- Report warnings for potential issues

**Expected Outcome**: Comprehensive pre-flight validation
**Estimated Time**: 45 minutes

### 2.4 Create validation test suite
**Action**: Create test cases for schema validation

**Test Cases**:
1. **Valid Configurations**
   - Minimal valid configuration
   - Full InfoTech.io configuration
   - Advanced features configuration

2. **Invalid Configurations**
   - Missing required fields (federation.name, etc.)
   - Invalid field types (string instead of object)
   - Pattern violations (invalid module name)
   - Constraint violations (empty modules array)

3. **Edge Cases**
   - Single module federation
   - Maximum modules (10+)
   - All optional fields omitted
   - All optional fields present

**Test Script**: `tests/test-modules-schema.sh`

**Expected Outcome**: 15+ test cases covering all validation scenarios
**Estimated Time**: 1.5 hours

### 2.5 Add schema validation to CI/CD
**Action**: Create GitHub Actions workflow for schema validation

**Workflow**: `.github/workflows/validate-schemas.yml`

**Jobs**:
1. Validate schema file itself
2. Validate all example configurations
3. Run validation test suite

**Triggers**:
- Push to any branch modifying schemas/ or examples/
- Pull requests

**Expected Outcome**: Automated schema validation in CI/CD
**Estimated Time**: 30 minutes

### 2.6 Update documentation
**Action**: Document schema validation and error handling

**Documentation Updates**:
1. Add schema reference documentation
2. Document validation error messages
3. Add troubleshooting guide for common errors
4. Update user guide with validation examples

**Files to Update**:
- `docs/content/user-guides/federated-builds.md` (create if needed)
- `docs/content/troubleshooting/schema-validation.md` (new)

**Expected Outcome**: Complete validation documentation
**Estimated Time**: 45 minutes

## Success Criteria
- [ ] federated-build.sh validates modules.json against schema
- [ ] Comprehensive error messages for all validation failures
- [ ] --validate-only flag provides detailed validation report
- [ ] Test suite with 15+ test cases (all passing)
- [ ] CI/CD workflow validates schemas automatically
- [ ] Documentation covers validation and troubleshooting

## Files Created
- `tests/test-modules-schema.sh` (new test suite)
- `.github/workflows/validate-schemas.yml` (new CI/CD workflow)
- `docs/content/troubleshooting/schema-validation.md` (new troubleshooting guide)

## Files Modified
- `scripts/federated-build.sh` (enhance load_modules_config function)
- `docs/content/user-guides/federated-builds.md` (add validation section)

## Testing Commands
```bash
# Test valid configuration
./scripts/federated-build.sh --config=docs/content/examples/modules-simple.json --validate-only

# Test invalid configuration (should fail gracefully)
./scripts/federated-build.sh --config=invalid-modules.json --validate-only

# Run validation test suite
./tests/test-modules-schema.sh

# Test CI/CD workflow locally
act -j validate-schemas
```

## Definition of Done
- Schema validation integrated into federated-build.sh
- All test cases pass (valid and invalid configurations)
- Error messages are clear and actionable
- CI/CD workflow passes for all example files
- Documentation complete and accurate
- No regressions in existing functionality

---

**Status**: ⬜ Not Started
**Dependencies**: Stage 1 must be completed (schema file exists)
**Assigned**: TBD
**Due Date**: TBD

**Implementation Notes**:
- Reuse existing Node.js inline script pattern from Stage 1 (Child #16)
- Consider using `ajv` npm package for JSON Schema validation
- Maintain backward compatibility with current error handling
- Keep validation fast (< 1 second for typical configurations)
- Provide suggestions for fixing common validation errors
