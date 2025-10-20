# Simple 2-Module Federation Tutorial

**Difficulty**: Beginner
**Time Required**: 15 minutes
**Prerequisites**: Hugo installed, basic command-line knowledge

---

## Overview

This tutorial walks you through creating your first federated Hugo site by merging two independent modules into a single unified site.

**What You'll Build**:
- Base site with homepage
- Module with additional content (e.g., blog)
- Merged federated site

**What You'll Learn**:
- Basic federation configuration
- Running federated builds
- Verifying merged output

---

## Step 1: Set Up Base Site (3 minutes)

### 1.1 Create Base Site Directory

```bash
mkdir -p federation-tutorial/base-site
cd federation-tutorial/base-site
```

### 1.2 Initialize Hugo Site

```bash
hugo new site . --force
```

### 1.3 Create Homepage Content

```bash
mkdir -p content
cat > content/_index.md <<'EOF'
---
title: "Welcome to My Site"
date: 2025-10-20
---

# Welcome

This is the base site homepage.

## About

This site demonstrates federated builds by merging content from multiple sources.
EOF
```

### 1.4 Create Basic Hugo Configuration

```bash
cat > hugo.toml <<'EOF'
baseURL = "https://example.com"
languageCode = "en-us"
title = "Federated Site Demo"
EOF
```

### 1.5 Test Base Site

```bash
hugo
# Should output: Total in X ms
ls public/  # Should show generated site
```

✅ **Checkpoint**: Base site builds successfully

---

## Step 2: Set Up Blog Module (3 minutes)

### 2.1 Create Module Directory

```bash
cd ..  # Back to federation-tutorial/
mkdir -p blog-module
cd blog-module
```

### 2.2 Initialize Hugo Site

```bash
hugo new site . --force
```

### 2.3 Create Blog Posts

```bash
mkdir -p content/blog
cat > content/blog/first-post.md <<'EOF'
---
title: "First Blog Post"
date: 2025-10-20
---

# First Post

This is content from the blog module.

## Module Independence

This module is developed and maintained separately from the base site.
EOF
```

```bash
cat > content/blog/second-post.md <<'EOF'
---
title: "Second Blog Post"
date: 2025-10-21
---

# Second Post

Another post from the blog module.

## Federation Benefits

- Independent development
- Separate repositories
- Unified deployment
EOF
```

### 2.4 Create Module Hugo Configuration

```bash
cat > hugo.toml <<'EOF'
baseURL = "https://example.com"
languageCode = "en-us"
title = "Blog Module"
EOF
```

### 2.5 Test Module

```bash
hugo
ls public/  # Should show generated site with blog/
```

✅ **Checkpoint**: Blog module builds successfully

---

## Step 3: Create Federation Configuration (2 minutes)

### 3.1 Navigate to Project Root

```bash
cd ..  # Back to federation-tutorial/
```

### 3.2 Create modules.json

```bash
cat > modules.json <<'EOF'
{
  "$schema": "../schemas/modules.schema.json",
  "baseSite": {
    "name": "main-site",
    "source": {
      "type": "local",
      "path": "./base-site"
    }
  },
  "modules": [
    {
      "name": "blog-module",
      "source": {
        "type": "local",
        "path": "./blog-module"
      },
      "priority": 1
    }
  ],
  "strategy": "merge-and-build"
}
EOF
```

### 3.3 Understand Configuration

Let's break down the configuration:

**baseSite**: Your main site (homepage, core content)
- `type: "local"` - Module is on local filesystem
- `path: "./base-site"` - Relative path to base site

**modules**: Array of additional modules to merge
- `name` - Unique identifier for this module
- `source` - Where to find the module
- `priority` - Merge order (higher = merged later, overwrites conflicts)

**strategy**: How to perform federation
- `merge-and-build` - Build all modules from source, then merge

✅ **Checkpoint**: Configuration file created

---

## Step 4: Run Federated Build (2 minutes)

### 4.1 Copy federated-build.sh

**Option A**: If you're in hugo-templates repo:
```bash
cp ../../scripts/federated-build.sh .
```

**Option B**: If standalone, download the script:
```bash
# Clone only the script
curl -O https://raw.githubusercontent.com/info-tech-io/hugo-templates/main/scripts/federated-build.sh
chmod +x federated-build.sh
```

### 4.2 Run Federation Build

```bash
./federated-build.sh --config=modules.json --output=federated-output
```

**Expected Output**:
```
ℹ️  Loading federation configuration from: modules.json
✅ Configuration validated successfully
📦 Building base site: main-site
✅ Base site built successfully
📦 Building module: blog-module (priority: 1)
✅ Module built successfully
🔀 Merging content from 1 module(s)
✅ Module blog-module merged successfully
✅ Federation build complete!
Output: federated-output/
```

✅ **Checkpoint**: Federation build completes successfully

---

## Step 5: Verify Merged Output (2 minutes)

### 5.1 Check Directory Structure

```bash
tree federated-output/ -L 2
```

**Expected Structure**:
```
federated-output/
├── index.html           # From base site
├── blog/
│   ├── first-post/      # From blog module
│   │   └── index.html
│   └── second-post/     # From blog module
│       └── index.html
└── [other Hugo files]
```

### 5.2 Verify Homepage

```bash
cat federated-output/index.html | grep "Welcome to My Site"
# Should show: <title>Welcome to My Site</title>
```

✅ Base site content present

### 5.3 Verify Blog Posts

```bash
ls federated-output/blog/
# Should show: first-post/  second-post/
```

✅ Blog module content merged

### 5.4 Serve Site Locally

```bash
cd federated-output
python3 -m http.server 8000
```

**Open browser**: http://localhost:8000

**Verify**:
- Homepage loads (base site)
- Navigate to `/blog/first-post/` (blog module)
- Navigate to `/blog/second-post/` (blog module)

✅ **Checkpoint**: All content accessible

---

## Step 6: Test Dry Run (2 minutes)

### 6.1 Test Configuration Without Building

```bash
cd ..  # Back to federation-tutorial/
./federated-build.sh --config=modules.json --dry-run
```

**Expected Output**:
```
ℹ️  DRY RUN MODE - No builds will be performed
ℹ️  Loading federation configuration from: modules.json
✅ Configuration validated successfully
✅ Base site source accessible: ./base-site
✅ Module source accessible: ./blog-module
✅ Dry run complete - configuration is valid
```

**Use Case**: Test configuration changes before running full build

---

## Step 7: Experiment (Optional - 1 minute)

### 7.1 Add More Content to Base Site

```bash
cat > base-site/content/about.md <<'EOF'
---
title: "About Us"
date: 2025-10-20
---

# About Us

This page is from the base site.
EOF
```

### 7.2 Rebuild Federation

```bash
./federated-build.sh --config=modules.json --output=federated-output
```

### 7.3 Verify New Content

```bash
ls federated-output/ | grep about
# Should show: about/
```

✅ New content appears in merged site

---

## What You Learned

✅ **Federation Basics**:
- Created 2-module federation (base site + blog module)
- Configured `modules.json` for local sources
- Ran federated build successfully

✅ **Key Concepts**:
- **Base Site**: Core content and homepage
- **Modules**: Independent content sections
- **Merge Strategy**: `merge-and-build` builds all from source
- **Local Sources**: Use `type: "local"` for local filesystem

✅ **Practical Skills**:
- Created federation configuration
- Validated configuration with dry-run
- Verified merged output
- Tested site locally

---

## Next Steps

### Extend This Tutorial

1. **Add Third Module**:
   - Create `docs-module` directory
   - Add to `modules.json`
   - Rebuild federation

2. **Use Git Sources**:
   - Push modules to GitHub
   - Update `modules.json` to use `type: "git"`
   - Test remote module fetching

3. **Try Other Strategies**:
   - Change strategy to `preserve-base-site`
   - Observe difference in merge behavior

### Learn More

**Advanced Features**:
- [Advanced 5-Module Tutorial](federation-advanced-tutorial.md) - Production scenario
- [Federated Builds Guide](../user-guides/federated-builds.md) - Complete reference

**Migration**:
- [Migration Checklist](federation-migration-checklist.md) - Migrate existing site

**Compatibility**:
- [Compatibility Guide](../user-guides/federation-compatibility.md) - When to use federation

---

## Troubleshooting

### Issue: Script Not Found

**Error**: `./federated-build.sh: No such file or directory`

**Solution**:
```bash
# Verify script exists
ls -l federated-build.sh

# If not, copy from repo or download
curl -O https://raw.githubusercontent.com/info-tech-io/hugo-templates/main/scripts/federated-build.sh
chmod +x federated-build.sh
```

### Issue: Hugo Not Found

**Error**: `ERROR: Hugo not found`

**Solution**:
```bash
# macOS
brew install hugo

# Linux (Snap)
snap install hugo

# Verify installation
hugo version
```

### Issue: Configuration Validation Failed

**Error**: `ERROR: Configuration validation failed`

**Solution**:
- Check JSON syntax with `jsonlint` or online validator
- Ensure paths in `source.path` are correct and relative to modules.json
- Verify all required fields present

### Issue: Module Build Failed

**Error**: `ERROR: Module 'blog-module' build failed`

**Solution**:
- Test module builds independently: `cd blog-module && hugo`
- Check hugo.toml configuration
- Ensure content/ directory exists with valid markdown files

---

## Clean Up

To remove tutorial files:

```bash
cd ..  # Exit federation-tutorial/
rm -rf federation-tutorial/
```

---

**Tutorial Complete!** 🎉

You've successfully created your first federated Hugo site by merging two modules.

**Time Spent**: ~15 minutes
**Modules Created**: 2 (base site + blog)
**Lines of Config**: ~20 lines (modules.json)
**Result**: Unified site from distributed sources

**Ready for Production?** Try the [Advanced 5-Module Tutorial](federation-advanced-tutorial.md) next!

---

**Last Updated**: 2025-10-20
**Difficulty**: Beginner
**Category**: Tutorials > Federation
