# Stage 3: Output Management

## Objective
Implement the merging logic to combine individual module builds into the final federated directory structure.

## Detailed Steps

### 3.1 Create output directory structure
**Action**: Set up the final federated output directory structure
- Create root output directory
- Create subdirectories for each module destination
- Handle nested directory paths (e.g., /docs/quiz/)
- Validate directory permissions and accessibility

**Expected Outcome**: Proper federated directory structure
**Estimated Time**: 30 minutes

### 3.2 Implement file merging logic
**Action**: Copy each module's build output to its designated destination
- Copy files from temporary build directories
- Handle file conflicts and overwrites
- Preserve file permissions and timestamps
- Handle symbolic links appropriately

**Expected Outcome**: All module outputs merged correctly
**Estimated Time**: 45 minutes

### 3.3 Handle static asset conflicts
**Action**: Manage conflicts between module static assets
- Detect duplicate asset names
- Implement conflict resolution strategy
- Handle CSS, JS, and image file conflicts
- Maintain asset integrity across modules

**Expected Outcome**: Clean asset management without conflicts
**Estimated Time**: 30 minutes

### 3.4 Validate final output structure
**Action**: Verify the federated output is correct and complete
- Check all expected destinations are populated
- Validate Hugo site structure in each destination
- Verify relative links work correctly
- Test static asset accessibility

**Expected Outcome**: Fully validated federated output
**Estimated Time**: 30 minutes

### 3.5 Create federation summary
**Action**: Generate summary information about the federation build
- List all modules and their destinations
- Report file counts and sizes for each module
- Create federation manifest file
- Generate build completion report

**Expected Outcome**: Comprehensive federation build summary
**Estimated Time**: 15 minutes

## Success Criteria
- [ ] All module outputs are correctly placed in their destinations
- [ ] No file conflicts or corruption in merged output
- [ ] Static assets are accessible and functional
- [ ] Hugo site structure is maintained for each module
- [ ] Federation summary provides complete build information
- [ ] Output can be directly deployed to web server

## Files Modified
- `scripts/federated-build.sh` (add output management functions)

## Files Created
- `federation-manifest.json` (in output directory, describes federation structure)

## Testing Commands
```bash
# Test output structure
./scripts/federated-build.sh --config=test-modules.json --output=test-federation
find test-federation -type f | head -20

# Validate Hugo structure
hugo --source=test-federation --destination=test-serve serve --port 1313

# Check for conflicts
./scripts/federated-build.sh --config=conflict-modules.json --output=conflict-test
```

## Definition of Done
- Federation output directory contains all expected module content
- Each module is accessible at its designated URL path
- No broken links or missing assets
- Federation manifest accurately describes structure
- Output passes Hugo validation for each module destination

---

**Status**: ⬜ Not Started
**Dependencies**: Stage 2 must be completed
**Assigned**: TBD
**Due Date**: TBD

**Implementation Notes**:
- Use rsync or similar for efficient file copying
- Implement dry-run mode for testing merges
- Consider disk space usage for large federations
- Preserve Hugo's expectations for site structure