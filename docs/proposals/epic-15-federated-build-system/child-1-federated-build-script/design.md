# Design: Child #1 - Federated Build Script Foundation

## Problem Statement

Create a new `federated-build.sh` script that orchestrates multiple individual Hugo site builds to create a federated GitHub Pages structure, while maintaining complete backward compatibility with existing `build.sh` functionality.

## Technical Solution

### High-Level Approach
Create a **separate orchestration layer** that reuses existing `build.sh` logic:
- `federated-build.sh` reads `modules.json` configuration
- For each module, calls existing `build.sh` with appropriate parameters
- Manages temporary directories and merges results into final federated structure

### Core Architecture

```
federated-build.sh
    ↓ reads modules.json
    ↓ for each module:
        ↓ calls build.sh --template=X --output=temp/module-X
        ↓ applies CSS path fixes if needed
        ↓ merges to final output directory
```

## Implementation Stages

### Stage 1: Script Foundation
Create basic `federated-build.sh` with modules.json parsing
- **Scope**: Basic script structure, argument parsing, modules.json loading
- **Files**: `scripts/federated-build.sh`
- **Dependencies**: Node.js for JSON parsing

### Stage 2: Build Orchestration
Implement multiple build.sh execution logic
- **Scope**: Call build.sh for each module, manage temporary directories
- **Files**: Functions in `federated-build.sh`
- **Dependencies**: Existing build.sh functionality

### Stage 3: Output Management
Implement merging logic for federated structure
- **Scope**: Merge individual builds into final directory structure
- **Files**: Merge functions in `federated-build.sh`
- **Dependencies**: File system operations

## Detailed Implementation Plan

### Stage 1 Implementation Details

#### 1.1 Script Foundation Setup
- Create `scripts/federated-build.sh` with proper shebang and error handling
- Copy error handling patterns from existing `build.sh`
- Add parameter parsing for `--config=modules.json`

#### 1.2 Modules.json Parser
- Create Node.js inline script for JSON parsing (similar to module.json parser)
- Validate modules.json structure
- Extract module configuration array

#### 1.3 Basic Validation
- Check modules.json file exists and is valid JSON
- Validate each module has required fields
- Check source repositories exist or can be accessed

### Stage 2 Implementation Details

#### 2.1 Build Orchestration Logic
- Create temporary working directory for each module
- For each module in modules.json:
  - Determine source content location
  - Call `build.sh` with module-specific parameters
  - Capture build output and errors

#### 2.2 Module-Specific Parameters
- Convert modules.json module config to build.sh parameters
- Handle `destination` field for subdirectory targeting
- Pass through template, theme, and component specifications

### Stage 3 Implementation Details

#### 3.1 Output Merging
- Create final output directory structure
- Copy each module's build output to its designated destination
- Handle file conflicts and overwrites

#### 3.2 File Path Management
- Ensure relative paths work correctly in subdirectories
- Handle static assets and theme files
- Maintain proper Hugo site structure

## Configuration Schema (modules.json)

```json
{
  "federation": {
    "name": "info-tech-io-pages",
    "baseURL": "https://info-tech-io.github.io",
    "strategy": "download-merge-deploy"
  },
  "modules": [
    {
      "name": "corporate-site",
      "source": {
        "repository": "info-tech-io/info-tech",
        "path": "docs"
      },
      "module_json": "module.json",
      "destination": "/",
      "css_path_prefix": ""
    },
    {
      "name": "quiz-docs",
      "source": {
        "repository": "info-tech-io/quiz",
        "path": "docs"
      },
      "module_json": "module.json",
      "destination": "/docs/quiz/",
      "css_path_prefix": "/docs/quiz"
    }
  ]
}
```

## Backward Compatibility Strategy

### Zero Impact on Existing Builds
- `build.sh` remains completely unchanged
- All existing scripts, CI/CD, and workflows continue working
- `federated-build.sh` is purely additive functionality

### Progressive Enhancement
- Users can migrate to federated builds when ready
- Existing projects work as single modules in federation
- Clear migration path from single to federated builds

## Error Handling Strategy

### Build Isolation
- Each module build failure doesn't affect other modules
- Clear error reporting shows which module failed
- Option to continue federation build despite individual failures

### Validation Gates
- Pre-build validation of all modules.json configuration
- Check source repositories accessibility
- Validate destination path conflicts

## Testing Strategy

### Unit Testing
- JSON parsing validation
- Module configuration validation
- File path handling

### Integration Testing
- End-to-end federation build with multiple modules
- Error scenarios (missing repos, build failures)
- Output structure validation

### Performance Testing
- Build time comparison vs sequential individual builds
- Memory usage during parallel operations
- Large federation scalability

## Dependencies and Prerequisites

### Required Tools
- Bash shell environment
- Node.js 18+ for JSON processing
- Git for repository operations
- Existing Hugo Templates Framework

### External Dependencies
- Access to source repositories (GitHub, etc.)
- Write permissions to output directory
- Network connectivity for repository cloning

## Success Criteria

- [ ] `federated-build.sh --config=modules.json` executes successfully
- [ ] Multiple modules build and merge into correct directory structure
- [ ] Zero impact on existing `build.sh` functionality
- [ ] Comprehensive error handling and user feedback
- [ ] Clear validation of modules.json configuration
- [ ] Performance within acceptable limits (< 3x single build time)

## Files to Create/Modify

### New Files
- `scripts/federated-build.sh` (main federation build script)
- `docs/examples/modules.json` (example configuration)

### Modified Files
- None (maintaining backward compatibility)

## Estimated Timeline
**Total**: 1.0 day
- Stage 1: 0.4 days (Script foundation and JSON parsing)
- Stage 2: 0.4 days (Build orchestration)
- Stage 3: 0.2 days (Output merging and validation)

---

**Implementation Notes**:
- Focus on reusing existing `build.sh` logic rather than reimplementing
- Maintain consistent error handling patterns with current codebase
- Design for scalability - should handle 10+ modules efficiently