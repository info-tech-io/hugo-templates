# Advanced 5-Module Federation Tutorial

**Difficulty**: Intermediate
**Time Required**: 45 minutes
**Prerequisites**: Completed [Simple Tutorial](federation-simple-tutorial.md), GitHub account, basic Git knowledge

---

## Overview

This tutorial demonstrates a production-ready federated build scenario inspired by InfoTech.io: 5 independent teams, each with their own repository, merged into a unified documentation portal.

**What You'll Build**:
- Base site (main documentation)
- 4 additional modules (API, tutorials, blog, FAQ)
- Production federation using GitHub Releases
- CI/CD-ready configuration

**What You'll Learn**:
- Multi-module federation (5 modules)
- Using `download-merge-deploy` strategy
- GitHub Releases as module sources
- Priority-based merge resolution
- Production deployment setup

---

## Architecture: InfoTech.io Documentation Portal

### Team Structure

```
InfoTech.io Documentation Portal
│
├── Team 1: Core Documentation (Base Site)
│   Repository: info-tech-io/main-docs
│   Content: Homepage, getting started, architecture
│
├── Team 2: API Reference
│   Repository: info-tech-io/api-docs
│   Content: API documentation, endpoint references
│
├── Team 3: Tutorials
│   Repository: info-tech-io/tutorials
│   Content: Step-by-step guides, how-tos
│
├── Team 4: Blog
│   Repository: info-tech-io/blog
│   Content: News, announcements, technical posts
│
└── Team 5: FAQ & Troubleshooting
    Repository: info-tech-io/faq-docs
    Content: Common issues, Q&A, troubleshooting
```

### Federation Flow

```
1. Each team develops independently in their repo
2. Teams create GitHub Releases with built sites
3. Federation downloads pre-built releases
4. Content merged into unified portal
5. Deploy to GitHub Pages
```

**Key Benefit**: Teams work independently, deploy together.

---

## Step 1: Create Base Site Repository (10 minutes)

### 1.1 Create Repository Structure

```bash
mkdir -p infotech-federation/main-docs
cd infotech-federation/main-docs
git init
```

### 1.2 Initialize Hugo Site

```bash
hugo new site . --force
```

### 1.3 Create Main Documentation

```bash
mkdir -p content/docs
cat > content/_index.md <<'EOF'
---
title: "InfoTech.io Documentation"
date: 2025-10-20
---

# InfoTech.io Platform

Welcome to the unified documentation portal.

## Documentation Sections

- **Getting Started**: Quick start guides
- **API Reference**: Complete API documentation
- **Tutorials**: Step-by-step learning paths
- **Blog**: Latest news and updates
- **FAQ**: Common questions and troubleshooting
EOF
```

```bash
cat > content/docs/getting-started.md <<'EOF'
---
title: "Getting Started"
date: 2025-10-20
---

# Getting Started

This is the main getting started guide.

## Installation

Follow these steps to install InfoTech.io platform...
EOF
```

### 1.4 Create Hugo Configuration

```bash
cat > hugo.toml <<'EOF'
baseURL = "https://info-tech-io.github.io"
languageCode = "en-us"
title = "InfoTech.io Documentation"

[params]
  description = "Unified documentation portal"
  author = "InfoTech.io Team"
EOF
```

### 1.5 Build and Create GitHub Release

```bash
# Build site
hugo --minify

# Create Git repository
git add .
git commit -m "feat: initial main documentation site"

# Push to GitHub (assuming you created repo on GitHub)
git remote add origin https://github.com/YOUR_ORG/main-docs.git
git branch -M main
git push -u origin main

# Create release with built site (v1.0.0)
# Package public/ directory
tar -czf site-v1.0.0.tar.gz public/

# Create GitHub release
gh release create v1.0.0 site-v1.0.0.tar.gz \
  --title "Main Docs v1.0.0" \
  --notes "Initial release of main documentation"
```

✅ **Checkpoint**: Base site repository with v1.0.0 release

---

## Step 2: Create API Reference Module (8 minutes)

### 2.1 Create Module Repository

```bash
cd ..  # Back to infotech-federation/
mkdir -p api-docs
cd api-docs
git init
hugo new site . --force
```

### 2.2 Create API Documentation

```bash
mkdir -p content/api
cat > content/api/_index.md <<'EOF'
---
title: "API Reference"
date: 2025-10-20
---

# API Reference

Complete API documentation for InfoTech.io platform.

## Endpoints

- Authentication
- User Management
- Data Operations
EOF
```

```bash
cat > content/api/authentication.md <<'EOF'
---
title: "Authentication API"
date: 2025-10-20
---

# Authentication API

## POST /api/auth/login

Authenticate user and receive access token.

### Request Body

\`\`\`json
{
  "email": "user@example.com",
  "password": "secure_password"
}
\`\`\`

### Response

\`\`\`json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600
}
\`\`\`
EOF
```

### 2.3 Build and Release

```bash
cat > hugo.toml <<'EOF'
baseURL = "https://info-tech-io.github.io"
languageCode = "en-us"
title = "API Reference"
EOF
```

```bash
hugo --minify
git add .
git commit -m "feat: API reference documentation"
git remote add origin https://github.com/YOUR_ORG/api-docs.git
git branch -M main
git push -u origin main

# Create release
tar -czf site-v1.0.0.tar.gz public/
gh release create v1.0.0 site-v1.0.0.tar.gz \
  --title "API Docs v1.0.0" \
  --notes "Initial API reference"
```

✅ **Checkpoint**: API module with v1.0.0 release

---

## Step 3: Create Tutorials Module (6 minutes)

### 3.1 Create Module Repository

```bash
cd ..
mkdir -p tutorials
cd tutorials
git init
hugo new site . --force
```

### 3.2 Create Tutorials

```bash
mkdir -p content/tutorials
cat > content/tutorials/first-app.md <<'EOF'
---
title: "Build Your First App"
date: 2025-10-20
categories: ["beginner"]
---

# Build Your First App

Step-by-step guide to building your first InfoTech.io application.

## Prerequisites

- Node.js ≥ 18
- InfoTech.io CLI installed

## Step 1: Initialize Project

\`\`\`bash
infotech init my-first-app
cd my-first-app
\`\`\`

## Step 2: Configure Application

Edit `config.json` with your settings...
EOF
```

```bash
cat > content/tutorials/advanced-deployment.md <<'EOF'
---
title: "Advanced Deployment"
date: 2025-10-20
categories: ["advanced"]
---

# Advanced Deployment

Learn advanced deployment strategies for production.

## Topics Covered

- Blue-green deployment
- Canary releases
- Rollback strategies
EOF
```

### 3.3 Build and Release

```bash
cat > hugo.toml <<'EOF'
baseURL = "https://info-tech-io.github.io"
languageCode = "en-us"
title = "Tutorials"
EOF
```

```bash
hugo --minify
git add .
git commit -m "feat: initial tutorials"
git remote add origin https://github.com/YOUR_ORG/tutorials.git
git branch -M main
git push -u origin main

tar -czf site-v1.0.0.tar.gz public/
gh release create v1.0.0 site-v1.0.0.tar.gz \
  --title "Tutorials v1.0.0" \
  --notes "Initial tutorial collection"
```

✅ **Checkpoint**: Tutorials module with v1.0.0 release

---

## Step 4: Create Blog and FAQ Modules (10 minutes)

**Note**: For brevity, we'll use simplified versions. In production, these would be full sites.

### 4.1 Create Blog Module

```bash
cd ..
mkdir -p blog
cd blog
git init
hugo new site . --force

mkdir -p content/blog
cat > content/blog/launch-announcement.md <<'EOF'
---
title: "InfoTech.io Platform Launch"
date: 2025-10-20
author: "InfoTech Team"
---

# Platform Launch

We're excited to announce the launch of InfoTech.io!

## Features

- Unified documentation
- Federated build system
- Multi-team collaboration
EOF
```

```bash
cat > hugo.toml <<'EOF'
baseURL = "https://info-tech-io.github.io"
languageCode = "en-us"
title = "InfoTech Blog"
EOF
```

```bash
hugo --minify
git add .
git commit -m "feat: initial blog posts"
git remote add origin https://github.com/YOUR_ORG/blog.git
git branch -M main
git push -u origin main

tar -czf site-v1.0.0.tar.gz public/
gh release create v1.0.0 site-v1.0.0.tar.gz \
  --title "Blog v1.0.0" \
  --notes "Initial blog posts"
```

### 4.2 Create FAQ Module

```bash
cd ..
mkdir -p faq-docs
cd faq-docs
git init
hugo new site . --force

mkdir -p content/faq
cat > content/faq/_index.md <<'EOF'
---
title: "FAQ & Troubleshooting"
date: 2025-10-20
---

# Frequently Asked Questions

## Installation Issues

**Q: Hugo not found?**
A: Install Hugo Extended ≥ 0.148.0

**Q: Build fails with SCSS error?**
A: Ensure Hugo Extended version is installed (not standard)

## Configuration Issues

**Q: Module not found?**
A: Verify repository URL and access permissions
EOF
```

```bash
cat > hugo.toml <<'EOF'
baseURL = "https://info-tech-io.github.io"
languageCode = "en-us"
title = "FAQ & Troubleshooting"
EOF
```

```bash
hugo --minify
git add .
git commit -m "feat: initial FAQ content"
git remote add origin https://github.com/YOUR_ORG/faq-docs.git
git branch -M main
git push -u origin main

tar -czf site-v1.0.0.tar.gz public/
gh release create v1.0.0 site-v1.0.0.tar.gz \
  --title "FAQ v1.0.0" \
  --notes "Initial FAQ and troubleshooting"
```

✅ **Checkpoint**: All 5 modules created with GitHub Releases

---

## Step 5: Create Production Federation Configuration (5 minutes)

### 5.1 Navigate to Federation Root

```bash
cd ..  # Back to infotech-federation/
```

### 5.2 Create modules.json

```bash
cat > modules.json <<'EOF'
{
  "$schema": "../schemas/modules.schema.json",
  "baseSite": {
    "name": "main-docs",
    "source": {
      "type": "github",
      "repo": "YOUR_ORG/main-docs",
      "tag": "v1.0.0"
    }
  },
  "modules": [
    {
      "name": "api-reference",
      "source": {
        "type": "github",
        "repo": "YOUR_ORG/api-docs",
        "tag": "v1.0.0"
      },
      "priority": 1
    },
    {
      "name": "tutorials",
      "source": {
        "type": "github",
        "repo": "YOUR_ORG/tutorials",
        "tag": "v1.0.0"
      },
      "priority": 2
    },
    {
      "name": "blog",
      "source": {
        "type": "github",
        "repo": "YOUR_ORG/blog",
        "tag": "v1.0.0"
      },
      "priority": 3
    },
    {
      "name": "faq",
      "source": {
        "type": "github",
        "repo": "YOUR_ORG/faq-docs",
        "tag": "v1.0.0"
      },
      "priority": 4
    }
  ],
  "strategy": "download-merge-deploy"
}
EOF
```

**Important**: Replace `YOUR_ORG` with your actual GitHub organization or username.

### 5.3 Understand Configuration

**Strategy**: `download-merge-deploy`
- Downloads pre-built sites from GitHub Releases
- No module building required (fastest)
- Perfect for CI/CD pipelines

**Priority**: Controls merge order
- Higher priority = merged later = overwrites conflicts
- FAQ (priority 4) overwrites blog (priority 3) in case of conflicts

**Source Type**: `github`
- Automatically downloads release assets
- Requires `repo` (repository path) and `tag` (release tag)

✅ **Checkpoint**: Production configuration created

---

## Step 6: Run Production Federation Build (3 minutes)

### 6.1 Download federated-build.sh

```bash
curl -O https://raw.githubusercontent.com/info-tech-io/hugo-templates/main/scripts/federated-build.sh
chmod +x federated-build.sh
```

### 6.2 Run Federation Build

```bash
./federated-build.sh \
  --config=modules.json \
  --output=public \
  --minify
```

**Expected Output**:
```
ℹ️  Loading federation configuration from: modules.json
✅ Configuration validated successfully
📦 Downloading base site from GitHub Release: YOUR_ORG/main-docs@v1.0.0
✅ Base site downloaded successfully
📦 Downloading module: api-reference (YOUR_ORG/api-docs@v1.0.0)
✅ Module downloaded successfully
📦 Downloading module: tutorials (YOUR_ORG/tutorials@v1.0.0)
✅ Module downloaded successfully
📦 Downloading module: blog (YOUR_ORG/blog@v1.0.0)
✅ Module downloaded successfully
📦 Downloading module: faq (YOUR_ORG/faq-docs@v1.0.0)
✅ Module downloaded successfully
🔀 Merging content from 4 module(s)
✅ All modules merged successfully
🗜️  Minifying output
✅ Federation build complete!
Output: public/
Total time: ~45 seconds
```

✅ **Checkpoint**: Federation build successful

---

## Step 7: Verify Production Output (3 minutes)

### 7.1 Check Merged Structure

```bash
tree public/ -L 2 -d
```

**Expected Structure**:
```
public/
├── docs/          # From main-docs (base site)
├── api/           # From api-docs module
├── tutorials/     # From tutorials module
├── blog/          # From blog module
└── faq/           # From faq module
```

### 7.2 Verify All Content Present

```bash
# Main docs
ls public/docs/
# Should show: getting-started/

# API reference
ls public/api/
# Should show: authentication/

# Tutorials
ls public/tutorials/
# Should show: first-app/ advanced-deployment/

# Blog
ls public/blog/
# Should show: launch-announcement/

# FAQ
ls public/faq/
# Should show: index.html
```

✅ All modules merged successfully

### 7.3 Serve Production Site

```bash
cd public
python3 -m http.server 8000
```

**Open browser**: http://localhost:8000

**Navigate to**:
- `/` - Homepage (main docs)
- `/docs/getting-started/` - Main documentation
- `/api/authentication/` - API reference
- `/tutorials/first-app/` - Tutorials
- `/blog/launch-announcement/` - Blog
- `/faq/` - FAQ

✅ **Checkpoint**: All content accessible in unified portal

---

## Step 8: CI/CD Integration (5 minutes)

### 8.1 Create GitHub Actions Workflow

```bash
mkdir -p .github/workflows
cat > .github/workflows/deploy.yml <<'EOF'
name: Deploy Federated Site

on:
  push:
    branches: [main]
  schedule:
    # Rebuild daily to fetch latest module releases
    - cron: '0 0 * * *'
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'
          extended: true

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Run Federated Build
        run: |
          chmod +x scripts/federated-build.sh
          ./scripts/federated-build.sh \
            --config=modules.json \
            --output=public \
            --minify

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
          cname: docs.infotech.io  # Optional: custom domain
EOF
```

### 8.2 Understand Workflow

**Triggers**:
- `push` to main branch - Deploy on changes to federation config
- `schedule` (daily) - Rebuild to fetch latest module releases
- `workflow_dispatch` - Manual trigger

**Steps**:
1. Checkout federation repository
2. Setup Hugo and Node.js
3. Run federated build (downloads all releases)
4. Deploy merged site to GitHub Pages

**Key Benefit**: Modules can release independently, federation rebuilds automatically.

### 8.3 Enable GitHub Pages

1. Go to repository Settings → Pages
2. Source: Deploy from a branch
3. Branch: `gh-pages` (created by workflow)
4. Save

✅ **Checkpoint**: CI/CD pipeline configured

---

## Step 9: Test Module Updates (5 minutes)

### 9.1 Update API Module

```bash
cd api-docs/
cat > content/api/users.md <<'EOF'
---
title: "Users API"
date: 2025-10-21
---

# Users API

## GET /api/users

List all users.

### Response

\`\`\`json
{
  "users": [
    {"id": 1, "name": "John Doe"},
    {"id": 2, "name": "Jane Smith"}
  ]
}
\`\`\`
EOF
```

### 9.2 Create New Release

```bash
hugo --minify
git add content/api/users.md
git commit -m "feat: add users API documentation"
git push

# Create v1.1.0 release
tar -czf site-v1.1.0.tar.gz public/
gh release create v1.1.0 site-v1.1.0.tar.gz \
  --title "API Docs v1.1.0" \
  --notes "Added Users API documentation"
```

### 9.3 Update Federation Configuration

```bash
cd ..  # Back to federation root

# Update api-reference module tag to v1.1.0
sed -i 's/"tag": "v1.0.0"/"tag": "v1.1.0"/g' modules.json
# (Manual edit for specific module recommended)
```

Edit `modules.json`:
```json
{
  "name": "api-reference",
  "source": {
    "type": "github",
    "repo": "YOUR_ORG/api-docs",
    "tag": "v1.1.0"  // Changed from v1.0.0
  },
  "priority": 1
}
```

### 9.4 Rebuild Federation

```bash
./federated-build.sh --config=modules.json --output=public --minify
```

### 9.5 Verify Update

```bash
ls public/api/ | grep users
# Should show: users/
```

✅ Module updated independently, federation rebuilt

---

## Production Best Practices

### Version Pinning

**Always use specific tags**:
```json
{
  "tag": "v1.0.0"  // ✅ Specific version
}
```

**Never use**:
```json
{
  "tag": "latest"  // ❌ Unpredictable
}
```

### Module Priorities

**Set priorities strategically**:
- Base site: No priority (foundation)
- Core modules: Low priority (1-2)
- Override modules: High priority (8-9)
- FAQ/Troubleshooting: Highest priority (10)

**Rationale**: FAQ should overwrite conflicting paths from other modules.

### Release Naming

**Consistent versioning**:
- `v1.0.0` - Major release
- `v1.1.0` - Minor update (new features)
- `v1.1.1` - Patch (bug fixes)

**Release notes**: Always include meaningful release notes.

### Automated Rebuilds

**Schedule federation builds**:
```yaml
schedule:
  - cron: '0 0 * * *'  # Daily at midnight
```

**Benefits**:
- Automatically picks up new module releases
- No manual intervention required
- Keep site up-to-date

### Monitoring

**Track build metrics**:
- Build time (target: < 2 minutes)
- Module download time
- Merge conflicts
- Failed builds

**Alerts**: Set up notifications for failed builds.

---

## Comparison: Simple vs Advanced

| Aspect | Simple Tutorial | Advanced Tutorial |
|--------|----------------|-------------------|
| Modules | 2 modules | 5 modules |
| Sources | Local filesystem | GitHub Releases |
| Strategy | `merge-and-build` | `download-merge-deploy` |
| Build Time | ~30 seconds | ~45 seconds |
| Use Case | Development | Production |
| CI/CD | Manual | Automated |
| Team Structure | Single developer | 5 independent teams |
| Deployment | Local testing | GitHub Pages |

---

## What You Learned

✅ **Production Federation**:
- Created 5-module federation (InfoTech.io scenario)
- Used GitHub Releases as module sources
- Configured `download-merge-deploy` strategy
- Set up CI/CD with GitHub Actions

✅ **Advanced Concepts**:
- Multi-team collaboration workflow
- Priority-based merge resolution
- Version pinning with Git tags
- Automated daily rebuilds

✅ **Real-World Skills**:
- Module independence (teams work separately)
- Centralized deployment (one unified portal)
- Production-ready configuration
- CI/CD integration

---

## Next Steps

### Extend This Setup

1. **Add Custom Domain**:
   - Update `cname` in GitHub Actions workflow
   - Configure DNS records

2. **Add Module Dependencies**:
   - Document which modules depend on others
   - Update federation order accordingly

3. **Implement Staging**:
   - Create `modules-staging.json`
   - Use pre-release tags (v1.1.0-beta)
   - Deploy to staging environment first

### Advanced Features

**Try These**:
- Module-specific CSS path prefixes
- Build options (timeouts, priorities)
- Conflict resolution strategies
- Performance optimization

**Learn More**:
- [Federation Architecture](../developer-docs/federation-architecture.md) - Technical design
- [API Reference](../developer-docs/federation-api-reference.md) - 28 functions documented
- [Compatibility Guide](../user-guides/federation-compatibility.md) - Decision matrix

---

## Troubleshooting

### Issue: GitHub Release Not Found

**Error**: `ERROR: Release v1.0.0 not found in repository YOUR_ORG/main-docs`

**Solutions**:
- Verify release exists: `gh release list --repo YOUR_ORG/main-docs`
- Check tag name matches exactly (case-sensitive)
- Ensure repository is public or credentials are configured

### Issue: Download Timeout

**Error**: `ERROR: Download timeout for module api-reference`

**Solutions**:
- Check internet connection
- Verify GitHub is accessible
- Increase timeout in configuration:
```json
{
  "build_options": {
    "build_timeout": 900
  }
}
```

### Issue: Merge Conflict

**Warning**: `WARNING: Conflict detected in path: about.md`

**Solutions**:
- Review module priorities
- Adjust priority to control which module wins
- Or restructure content to avoid overlaps

---

## Clean Up

To remove tutorial files:

```bash
# Remove local directories
cd ..
rm -rf infotech-federation/

# Delete GitHub repositories (optional)
# gh repo delete YOUR_ORG/main-docs --yes
# gh repo delete YOUR_ORG/api-docs --yes
# ... (repeat for all modules)
```

---

**Tutorial Complete!** 🎉

You've built a production-ready federated Hugo site with 5 independent modules, simulating the InfoTech.io multi-team documentation portal.

**What You Built**:
- **5 repositories**: main-docs, api-docs, tutorials, blog, faq-docs
- **5 GitHub Releases**: v1.0.0 for each module
- **1 unified portal**: Merged from all sources
- **CI/CD pipeline**: Automated daily rebuilds

**Time Spent**: ~45 minutes
**Modules**: 5 (multi-team scenario)
**Strategy**: download-merge-deploy (production-ready)
**Deployment**: GitHub Pages with automation

**Ready to Migrate?** See the [Migration Checklist](federation-migration-checklist.md) to migrate your existing site.

---

**Last Updated**: 2025-10-20
**Difficulty**: Intermediate
**Category**: Tutorials > Federation
**Production-Ready**: Yes ✅
