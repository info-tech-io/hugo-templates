# Design: Child #3 - CSS Path Resolution System

## Problem Statement
Implement dynamic CSS path resolution to ensure themes and static assets work correctly when deployed in subdirectories (e.g., `/docs/quiz/`) rather than site root.

## Technical Solution

### CSS Path Challenge
Hugo themes expect to be deployed at site root. When deployed in subdirectories:
- CSS links like `/css/style.css` fail (should be `/docs/quiz/css/style.css`)
- Asset references need path prefixes
- Theme configurations need adjustment

### Resolution Strategy
1. **Pre-build Path Injection**: Modify Hugo configuration before build
2. **Post-build Path Rewriting**: Process generated HTML/CSS after build
3. **Theme Configuration**: Adjust theme settings for subdirectory deployment

## Implementation Stages

### Stage 1: Path Detection System
- Analyze module destination paths
- Determine required CSS path prefixes
- Create path mapping configuration

### Stage 2: Hugo Configuration Modification
- Modify Hugo config.toml/yaml before build
- Set appropriate baseURL for each module
- Configure theme parameters for subdirectory deployment

### Stage 3: Post-Build Asset Processing
- Process generated HTML files for path corrections
- Rewrite CSS imports and asset references
- Handle JavaScript and image path adjustments

## Key Functions
- `calculate_css_prefix(destination_path)`
- `modify_hugo_config(config_file, css_prefix)`
- `rewrite_asset_paths(output_dir, css_prefix)`

**Estimated Time**: 1.5 days