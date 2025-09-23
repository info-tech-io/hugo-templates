---
title: "Templates"
description: "Complete guide to Hugo Templates Framework templates and their usage"
weight: 20
---

# Templates Guide

Hugo Templates Framework provides three specialized templates, each optimized for different types of websites. Each template includes pre-configured layouts, content structure, and theme integration to help you build professional sites quickly.

## Overview of Available Templates

| Template | Best For | Key Features | Example Sites |
|----------|----------|--------------|---------------|
| **Educational** | Learning platforms, courses | Quiz integration, progress tracking | [INFOTECHA](https://infotecha.ru) |
| **Corporate** | Company websites, organizations | Product catalogs, blogs, SEO | [Info-Tech.io](https://info-tech-io.github.io) |
| **Documentation** | Technical docs, API references | Search, navigation, code highlighting | This documentation site |

## Template Structure

All templates follow a consistent structure:

```
templates/[template-name]/
├── hugo.toml.template      # Hugo configuration template
├── module.json            # Template metadata and defaults
├── layouts/               # Hugo layout files
├── content/               # Example content structure
├── static/                # Static assets
├── data/                  # Data files and configurations
└── README.md              # Template-specific documentation
```

---

## 🎓 Educational Template

The Educational template is designed for learning platforms, online courses, and educational content.

### Key Features

- **Quiz Engine Integration** - Built-in support for interactive quizzes and tests
- **Progressive Structure** - Organized learning paths with modules and lessons
- **Multi-language Support** - Full internationalization for global audiences
- **Progress Tracking** - Student advancement monitoring (coming soon)
- **Mobile Optimized** - Responsive design for learning on any device

### Content Structure

```
content/
├── _index.md              # Course overview
├── intro/                 # Introduction module
│   ├── _index.md
│   ├── lesson-01.md
│   └── quiz-01.json
├── module-01/             # Learning modules
│   ├── _index.md
│   ├── topic-01/
│   ├── topic-02/
│   └── assessment/
└── resources/             # Additional resources
    ├── glossary.md
    └── references.md
```

### Usage Example

```bash
./scripts/build.sh \
  --template educational \
  --components quiz-engine \
  --content course-content/ \
  --base-url "https://learn.example.com" \
  --output learning-site
```

### Configuration Options

```json
{
  "template": "educational",
  "config": {
    "enableQuizEngine": true,
    "showProgress": true,
    "allowComments": false,
    "trackingEnabled": true
  },
  "theme": "compose",
  "components": ["quiz-engine", "analytics"]
}
```

### Best Practices

- **Structure content hierarchically** - Use modules → topics → lessons
- **Include assessments** - Add quizzes at the end of each module
- **Provide navigation aids** - Clear learning paths and progress indicators
- **Test on mobile** - Ensure content is readable on small screens

---

## 🏢 Corporate Template

The Corporate template is perfect for business websites, organizations, and product showcases.

### Key Features

- **Product Showcase** - Dedicated sections for highlighting products/services
- **Blog System** - Built-in blog with categories and tags
- **SEO Optimized** - Structured data, meta tags, and sitemap generation
- **Contact Forms** - Ready-to-use contact and inquiry forms
- **Team Pages** - Professional team member profiles
- **News & Updates** - Announcement and news management

### Content Structure

```
content/
├── _index.md              # Homepage
├── about/                 # About the organization
│   ├── _index.md
│   ├── mission.md
│   ├── team.md
│   └── history.md
├── products/              # Product catalog
│   ├── _index.md
│   ├── product-a.md
│   └── product-b.md
├── blog/                  # Blog posts
│   ├── _index.md
│   └── posts/
├── news/                  # News and announcements
│   ├── _index.md
│   └── items/
└── contact/               # Contact information
    └── _index.md
```

### Usage Example

```bash
./scripts/build.sh \
  --template corporate \
  --theme compose \
  --components analytics,search \
  --base-url "https://company.com" \
  --output company-site
```

### Configuration Options

```json
{
  "template": "corporate",
  "config": {
    "enableBlog": true,
    "enableSearch": true,
    "showSocial": true,
    "contactForm": true
  },
  "theme": "compose",
  "components": ["analytics", "search", "contact-form"]
}
```

### Best Practices

- **Focus on value proposition** - Clear messaging about what you offer
- **Use high-quality images** - Professional photos for products and team
- **Optimize for search** - Include relevant keywords and meta descriptions
- **Include social proof** - Customer testimonials and case studies
- **Make contact easy** - Multiple ways to reach your organization

---

## 📚 Documentation Template

The Documentation template is optimized for technical documentation, API references, and user guides.

### Key Features

- **Hierarchical Navigation** - Multi-level documentation organization
- **Search Integration** - Full-text search across all documentation
- **Code Highlighting** - Syntax highlighting for multiple languages
- **API Documentation** - Structured API reference sections
- **Version Management** - Support for multiple documentation versions
- **Cross-references** - Easy linking between documentation sections

### Content Structure

```
content/
├── _index.md              # Documentation home
├── getting-started/       # Quick start guides
│   ├── _index.md
│   ├── installation.md
│   └── quickstart.md
├── user-guide/            # User documentation
│   ├── _index.md
│   ├── configuration.md
│   └── advanced.md
├── developer/             # Developer documentation
│   ├── _index.md
│   ├── api/
│   ├── architecture.md
│   └── contributing.md
├── examples/              # Code examples
│   ├── _index.md
│   ├── basic.md
│   └── advanced.md
└── faq/                   # Frequently asked questions
    └── _index.md
```

### Usage Example

```bash
./scripts/build.sh \
  --template documentation \
  --components search,syntax-highlighting \
  --content docs/content/ \
  --base-url "https://docs.example.com" \
  --output docs-site
```

### Configuration Options

```json
{
  "template": "documentation",
  "config": {
    "enableSearch": true,
    "syntaxHighlighting": true,
    "showEditLinks": true,
    "enableComments": false
  },
  "theme": "compose",
  "components": ["search", "syntax-highlighting"]
}
```

### Best Practices

- **Organize logically** - Structure from basic to advanced topics
- **Include code examples** - Practical examples for every concept
- **Cross-reference content** - Link related topics together
- **Keep it updated** - Regular reviews and updates for accuracy
- **Test examples** - Ensure all code samples actually work

---

## Customizing Templates

### Modifying Layouts

Each template includes customizable layouts in the `layouts/` directory:

```
layouts/
├── _default/              # Default page layouts
├── partials/              # Reusable template parts
├── shortcodes/            # Custom Hugo shortcodes
└── index.html             # Homepage layout
```

### Adding Custom Content Types

You can extend templates with custom content types:

```yaml
# In hugo.toml
[params]
  customContentTypes = ["case-studies", "tutorials", "resources"]
```

### Theme Integration

Templates work with any Hugo theme, but are optimized for:

- **Compose** (default) - Modern, clean design
- **Minimal** - Lightweight and fast
- **Dark** - Dark mode optimized

## Advanced Usage

### Multi-site Setup

Use Hugo Templates Framework to manage multiple related sites:

```bash
# Main corporate site
./scripts/build.sh --template corporate --output company-site

# Documentation site
./scripts/build.sh --template documentation --output docs-site

# Learning platform
./scripts/build.sh --template educational --output learn-site
```

### CI/CD Integration

Automate site building in your CI/CD pipeline:

```yaml
# GitHub Actions example
- name: Build Documentation
  run: |
    ./scripts/build.sh \
      --template documentation \
      --content docs/content \
      --base-url ${{ env.DOCS_URL }} \
      --output build/docs
```

## Template Comparison

| Feature | Educational | Corporate | Documentation |
|---------|-------------|-----------|---------------|
| Quiz Integration | ✅ Built-in | ❌ Not included | ❌ Not included |
| Blog System | ❌ Not included | ✅ Full featured | ❌ Not included |
| Search | ⚠️ Basic | ✅ Advanced | ✅ Advanced |
| Multi-language | ✅ Full support | ⚠️ Basic | ⚠️ Basic |
| Mobile Optimization | ✅ Excellent | ✅ Good | ✅ Good |
| SEO Features | ⚠️ Basic | ✅ Advanced | ✅ Good |

## Next Steps

- **[Configuration Guide](/hugo/user-guide/configuration/)** - Learn about module.json configuration
- **[Build Scripts](/hugo/user-guide/build-scripts/)** - Master the build system
- **[Examples](/hugo/examples/)** - See templates in action
- **[Contributing](/hugo/contributing/)** - Help improve the templates

---

**Need help choosing a template?** Consider your primary use case:
- **Teaching/Learning?** → Educational Template
- **Business/Organization?** → Corporate Template
- **Documentation/Technical?** → Documentation Template