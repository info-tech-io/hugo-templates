# Template Usage Guide

## Overview

This guide covers how to work with templates in the Hugo Template Factory Framework, including selection, customization, and creation of new templates.

## Available Templates

### Template Overview

| Template | Description | Use Case | Components | Build Time |
|----------|-------------|----------|------------|------------|
| **minimal** | Lightweight template | Fast builds, simple sites | Essential only | < 30s |
| **default** | Full-featured template | General-purpose sites | All available | < 2min |
| **academic** | Academic template | Research, publications | Citations, papers | < 3min |
| **enterprise** | Corporate template | Business websites | Analytics, auth | < 5min |
| **educational** | Learning-focused | Educational platforms | Quiz engine, tracking | < 3min |

### Template Selection Guide

**Choose `minimal` when:**
- Development/testing phase
- Simple static sites
- Fast build times required
- Limited content

**Choose `default` when:**
- General-purpose websites
- Balanced feature set needed
- Standard blog or portfolio
- Moderate content volume

**Choose `academic` when:**
- Research publications
- Academic portfolios
- Citation management needed
- Bibliography integration required

**Choose `enterprise` when:**
- Corporate websites
- Analytics integration needed
- User authentication required
- Professional appearance

**Choose `educational` when:**
- Learning platforms
- Course materials
- Interactive content needed
- Progress tracking required

## Using Templates

### Basic Template Usage

```bash
# List available templates
./scripts/list.js --templates

# Build with specific template
./scripts/build.sh --template=default

# Build with template and theme
./scripts/build.sh --template=academic --theme=compose

# Build with custom output
./scripts/build.sh --template=enterprise --output=./my-site
```

### Template with Components

```bash
# Default template with quiz engine
./scripts/build.sh --template=default --components=quiz-engine

# Educational template with multiple components
./scripts/build.sh --template=educational --components=quiz-engine,analytics

# Enterprise template with all components
./scripts/build.sh --template=enterprise --components=quiz-engine,analytics,auth
```

### Advanced Template Options

```bash
# Production build with minification
./scripts/build.sh \
  --template=enterprise \
  --environment=production \
  --minify \
  --base-url=https://example.com

# Development build with drafts
./scripts/build.sh \
  --template=default \
  --environment=development \
  --draft \
  --verbose
```

## Template Structure

### Template Directory Layout

```
templates/
├── minimal/
│   ├── hugo.toml              # Hugo configuration
│   ├── components.yml         # Component configuration
│   ├── content/               # Default content
│   │   ├── _index.md         # Homepage content
│   │   └── about.md          # About page
│   ├── static/               # Static assets
│   │   ├── css/              # Stylesheets
│   │   ├── js/               # JavaScript files
│   │   └── images/           # Images
│   └── layouts/              # Custom layouts (optional)
├── default/
│   ├── hugo.toml
│   ├── components.yml
│   ├── content/
│   │   ├── _index.md
│   │   ├── about.md
│   │   ├── posts/            # Blog posts
│   │   └── projects/         # Project pages
│   ├── static/
│   └── layouts/
└── academic/
    ├── hugo.toml
    ├── components.yml
    ├── content/
    │   ├── _index.md
    │   ├── publications/      # Research papers
    │   ├── research/          # Research projects
    │   └── cv.md             # Curriculum Vitae
    ├── static/
    └── layouts/
```

### Configuration Files

#### hugo.toml Structure

```toml
# Basic configuration
baseURL = "http://localhost:1313"
title = "Site Title"
theme = "compose"
languageCode = "en-us"

# Build configuration
[markup]
  [markup.goldmark]
    [markup.goldmark.renderer]
      unsafe = true

# Menu configuration
[[menu.main]]
  name = "Home"
  url = "/"
  weight = 1

[[menu.main]]
  name = "About"
  url = "/about/"
  weight = 2

# Taxonomy configuration
[taxonomies]
  tag = "tags"
  category = "categories"

# Parameters
[params]
  description = "Site description"
  author = "Author Name"
```

#### components.yml Structure

```yaml
components:
  - name: quiz-engine
    version: "1.0.0"
    enabled: true
    config:
      theme: "default"
      show_progress: true

  - name: analytics
    version: "0.9.0"
    enabled: false
    config:
      provider: "google"
      tracking_id: ""
```

## Template Customization

### Content Customization

**1. Homepage Content (_index.md)**
```markdown
---
title: "Welcome to My Site"
description: "Site description for SEO"
---

# Welcome

This is the homepage content.
```

**2. About Page (about.md)**
```markdown
---
title: "About"
menu:
  main:
    weight: 2
---

# About Me

Information about the site owner.
```

**3. Blog Posts (posts/_index.md)**
```markdown
---
title: "Blog"
description: "Latest blog posts"
---

# Blog Posts

Collection of articles and thoughts.
```

### Styling Customization

**1. Custom CSS (static/css/custom.css)**
```css
/* Custom site styling */
:root {
  --primary-color: #007bff;
  --secondary-color: #6c757d;
}

.custom-header {
  background-color: var(--primary-color);
  color: white;
}
```

**2. Custom JavaScript (static/js/custom.js)**
```javascript
// Custom site functionality
document.addEventListener('DOMContentLoaded', function() {
  console.log('Site loaded');
});
```

### Layout Customization

**1. Custom Homepage Layout (layouts/index.html)**
```html
{{ define "main" }}
<div class="homepage">
  <h1>{{ .Title }}</h1>
  <div class="content">
    {{ .Content }}
  </div>

  <!-- Recent posts -->
  <section class="recent-posts">
    <h2>Recent Posts</h2>
    {{ range first 3 (where .Site.Pages "Type" "posts") }}
      <article>
        <h3><a href="{{ .Permalink }}">{{ .Title }}</a></h3>
        <p>{{ .Summary }}</p>
      </article>
    {{ end }}
  </section>
</div>
{{ end }}
```

## Creating Custom Templates

### Template Creation Process

1. **Copy Existing Template**
```bash
# Copy default template as base
cp -r templates/default templates/my-custom

# Navigate to new template
cd templates/my-custom
```

2. **Modify Configuration**
```bash
# Edit hugo.toml
nano hugo.toml

# Edit components.yml
nano components.yml
```

3. **Customize Content**
```bash
# Add custom content
mkdir content/portfolio
echo "---\ntitle: Portfolio\n---\n# My Work" > content/portfolio/_index.md
```

4. **Test Template**
```bash
# Build and test
./scripts/build.sh --template=my-custom --output=test-output

# Validate template
./scripts/validate.js --template=my-custom
```

### Template Best Practices

**1. Configuration Standards**
- Include all required Hugo configuration fields
- Use consistent naming conventions
- Document custom parameters

**2. Content Structure**
- Provide meaningful default content
- Include example posts/pages
- Use proper frontmatter

**3. Component Integration**
- Test with various component combinations
- Ensure components work with theme
- Provide component configuration examples

**4. Performance Considerations**
- Keep templates lightweight
- Optimize images and assets
- Use efficient Hugo template patterns

### Example: Blog Template

```bash
# Create blog-focused template
cp -r templates/default templates/blog

# Customize for blogging
cat > templates/blog/hugo.toml << 'EOF'
baseURL = "http://localhost:1313"
title = "My Blog"
theme = "compose"

[params]
  description = "Personal blog about technology"
  show_reading_time = true
  show_tags = true

[taxonomies]
  tag = "tags"
  category = "categories"

[[menu.main]]
  name = "Home"
  url = "/"
  weight = 1

[[menu.main]]
  name = "Posts"
  url = "/posts/"
  weight = 2

[[menu.main]]
  name = "Tags"
  url = "/tags/"
  weight = 3
EOF

# Add blog-specific content
mkdir -p templates/blog/content/posts
cat > templates/blog/content/posts/_index.md << 'EOF'
---
title: "Blog Posts"
description: "All blog posts"
---

# Blog Posts

Welcome to my blog! Here you'll find articles about technology, programming, and more.
EOF

# Create example post
cat > templates/blog/content/posts/first-post.md << 'EOF'
---
title: "Welcome to My Blog"
date: 2024-01-01
tags: ["blogging", "welcome"]
category: "general"
draft: false
---

This is my first blog post! I'm excited to share my thoughts and experiences.

## What to Expect

- Technology articles
- Programming tutorials
- Personal reflections

Stay tuned for more content!
EOF
```

## Template Validation

### Validation Commands

```bash
# Validate specific template
./scripts/validate.js --template=my-custom

# Validate template configuration
hugo config --source=./templates/my-custom

# Check template structure
./scripts/list.js --templates --format=json | jq '.templates[] | select(.name=="my-custom")'
```

### Common Validation Issues

**1. Missing Configuration**
```
[ERROR] Required field missing: baseURL
```
**Solution**: Add required fields to hugo.toml

**2. Invalid Content Structure**
```
[ERROR] Invalid frontmatter in content/_index.md
```
**Solution**: Fix YAML frontmatter syntax

**3. Component Conflicts**
```
[ERROR] Component quiz-engine not compatible with theme minimal
```
**Solution**: Use compatible theme or modify component configuration

## Template Migration

### Upgrading Templates

```bash
# Backup current template
cp -r templates/my-template templates/my-template-backup

# Update template files
# (manually update configuration and content)

# Test updated template
./scripts/build.sh --template=my-template --validate-only

# Compare outputs
diff -r old-output new-output
```

### Version Compatibility

**Template Version History:**
- v1.0: Basic template structure
- v1.1: Added component support
- v1.2: Enhanced configuration options
- v2.0: New layout system (current)

**Migration Checklist:**
- [ ] Update hugo.toml to new format
- [ ] Migrate component configurations
- [ ] Update custom layouts
- [ ] Test all template features
- [ ] Validate build process

## Related Documentation

- [Build System Guide](./build-system.md)
- [Component Development](../developer-docs/components.md)
- [Troubleshooting Guide](../troubleshooting/common-issues.md)
- [Installation Guide](./installation.md)