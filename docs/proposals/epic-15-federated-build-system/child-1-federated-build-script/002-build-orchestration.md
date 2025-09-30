# Stage 2: Build Orchestration

## Objective
Implement the core logic to orchestrate multiple build.sh executions for each module in the federation.

## Detailed Steps

### 2.1 Implement module iteration logic
**Action**: Create function to process each module from modules.json
- Parse modules array from configuration
- Create temporary directory for each module build
- Set up module-specific build parameters
- Handle module build isolation and cleanup

**Expected Outcome**: Framework for processing multiple modules
**Estimated Time**: 45 minutes

### 2.2 Create build.sh parameter mapping
**Action**: Convert modules.json module config to build.sh parameters
- Map module.module_json to --config parameter
- Extract template, theme, components from module configuration
- Handle source content directory specification
- Set temporary output directory for module

**Expected Outcome**: Correct parameter mapping for each module
**Estimated Time**: 1 hour

### 2.3 Implement build.sh execution
**Action**: Execute build.sh for each module with proper parameters
- Call existing build.sh with module-specific parameters
- Capture stdout and stderr for each build
- Handle build failures gracefully
- Provide progress indication for multiple builds

**Expected Outcome**: Successful execution of multiple builds
**Estimated Time**: 1 hour

### 2.4 Add parallel build support (optional)
**Action**: Implement optional parallel execution of module builds
- Add --parallel flag for concurrent builds
- Manage resource usage and build conflicts
- Handle parallel error reporting
- Fall back to sequential builds if needed

**Expected Outcome**: Optional parallel execution capability
**Estimated Time**: 45 minutes

### 2.5 Create build status reporting
**Action**: Implement comprehensive status reporting for federation build
- Report success/failure status for each module
- Provide build time statistics
- Create summary of federation build results
- Handle partial build failures

**Expected Outcome**: Clear visibility into federation build process
**Estimated Time**: 30 minutes

## Success Criteria
- [ ] Script successfully calls build.sh for each module
- [ ] Module-specific parameters are correctly mapped
- [ ] Build errors are captured and reported clearly
- [ ] Progress indication works for multiple modules
- [ ] Temporary directories are properly managed
- [ ] Build status summary is informative and accurate

## Files Modified
- `scripts/federated-build.sh` (add orchestration functions)

## Testing Commands
```bash
# Test with multiple modules
./scripts/federated-build.sh --config=test-modules.json --output=test-output

# Test with single module
./scripts/federated-build.sh --config=single-module.json --verbose

# Test error handling
./scripts/federated-build.sh --config=invalid-module.json
```

## Definition of Done
- All modules build successfully when configuration is valid
- Build failures are handled gracefully with informative messages
- Progress indication clearly shows current module being built
- Temporary files are cleaned up after builds
- Build timing and statistics are accurate

---

**Status**: ⬜ Not Started
**Dependencies**: Stage 1 must be completed
**Assigned**: TBD
**Due Date**: TBD

**Implementation Notes**:
- Reuse existing build.sh without modifications
- Maintain build isolation between modules
- Consider memory usage for parallel builds
- Preserve all build.sh output for debugging