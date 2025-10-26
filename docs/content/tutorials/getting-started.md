# Getting Started Tutorial

## Overview

This comprehensive tutorial walks you through creating your first site with the Hugo Template Factory Framework, from installation to deployment.

## What You'll Learn

- How to set up the Hugo Template Factory Framework
- Creating your first site with different templates
- Customizing content and configuration
- Adding components to enhance functionality
- Building and deploying your site

## Prerequisites

- Basic command line knowledge
- Text editor (VS Code recommended)
- Git installed on your system

## Step 1: Installation

### Quick Setup

```bash
# Clone the repository
git clone https://github.com/info-tech-io/hugo-templates.git
cd hugo-templates

# Initialize and install dependencies
git submodule update --init --recursive
npm ci

# Verify installation
./scripts/diagnostic.js --all
```

**Expected Output:**
```
✅ Hugo Extended v0.148.0 detected
✅ Node.js v18.x.x detected
✅ NPM v9.x.x detected
✅ Git v2.40.x detected
✅ Templates loaded: 5 templates
✅ Themes loaded: 1 theme
✅ Components loaded: 1 component
✅ Build system: Ready
```

### Install Missing Dependencies

If the diagnostic shows missing dependencies:

**Hugo Missing:**
```bash
# Ubuntu/Debian
wget -O hugo.deb https://github.com/gohugoio/hugo/releases/download/v0.148.0/hugo_extended_0.148.0_linux-amd64.deb
sudo dpkg -i hugo.deb

# macOS
brew install hugo

# Windows (with Chocolatey)
choco install hugo-extended
```

**Node.js Missing:**
```bash
# Using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18
```

## Step 2: Explore Available Resources

### List Templates

```bash
./scripts/list.js --templates
```

**Output:**
```
📋 Available Templates:
├── minimal     - Lightweight template for fast builds
├── default     - Full-featured template for general use
├── academic    - Academic template for research/publications
├── enterprise  - Corporate template with analytics/auth
└── educational - Learning-focused template with quiz engine
```

### List Themes

```bash
./scripts/list.js --themes
```

**Output:**
```
🎨 Available Themes:
└── compose     - Feature-rich responsive theme
```

### List Components

```bash
./scripts/list.js --components
```

**Output:**
```
🧩 Available Components:
└── quiz-engine - Interactive educational quiz system
```

## Step 3: Create Your First Site

### Option A: Minimal Site (Recommended for Beginners)

```bash
# Create a minimal site
./scripts/build.sh --template=minimal --output=my-first-site

# Verify the build
ls -la my-first-site/
```

**Expected Structure:**
```
my-first-site/
├── index.html          # Homepage
├── about/
│   └── index.html      # About page
├── css/
│   └── style.css       # Stylesheets
├── js/
│   └── main.js         # JavaScript
└── sitemap.xml         # Site map
```

### Option B: Full-Featured Site

```bash
# Create a full-featured site
./scripts/build.sh --template=default --output=my-blog

# With quiz engine component
./scripts/build.sh --template=default --components=quiz-engine --output=my-learning-site
```

### Option C: Educational Platform

```bash
# Create educational site with interactive features
./scripts/build.sh \
  --template=educational \
  --components=quiz-engine \
  --output=my-course-site
```

## Step 4: Preview Your Site

### Local Development Server

```bash
# Start Hugo development server from build directory
cd my-first-site
python3 -m http.server 8000

# Or use Node.js server
npx http-server . -p 8000

# Open in browser
open http://localhost:8000  # macOS
xdg-open http://localhost:8000  # Linux
start http://localhost:8000  # Windows
```

### Using Hugo Server Directly

```bash
# For live reloading during development
hugo server --source=./build-temp --port=1313

# Open in browser
open http://localhost:1313
```

## Step 5: Customize Your Site

### Edit Homepage Content

```bash
# Navigate back to project root
cd ../

# Edit the default template's homepage
nano templates/default/content/_index.md
```

**Example Content:**
```markdown
---
title: "Welcome to My Site"
description: "A personal blog about technology and life"
---

# Hello, World!

Welcome to my personal website. I'm excited to share my thoughts and experiences with you.

## What You'll Find Here

- Technology articles
- Personal reflections
- Project showcases
- Learning resources

## Recent Posts

Check out my latest blog posts below!
```

### Add a Blog Post

```bash
# Create a new blog post
mkdir -p templates/default/content/posts
cat > templates/default/content/posts/my-first-post.md << 'EOF'
---
title: "My First Blog Post"
date: 2024-01-15
tags: ["blogging", "getting-started"]
draft: false
---

This is my very first blog post! I'm excited to start sharing my thoughts and experiences.

## Why I Started Blogging

I wanted to create a space where I could:

1. Share my learning journey
2. Connect with like-minded people
3. Document my projects
4. Help others learn

## What's Next

Stay tuned for more posts about:

- Web development
- Technology trends
- Personal projects
- Learning resources
EOF
```

### Customize Site Configuration

```bash
# Edit Hugo configuration
nano templates/default/hugo.toml
```

**Update Configuration:**
```toml
baseURL = "http://localhost:1313"
title = "Your Name - Personal Blog"
theme = "compose"
languageCode = "en-us"

[params]
  description = "Personal blog about technology and life"
  author = "Your Name"
  email = "your.email@example.com"

  # Social links
  github = "your-github-username"
  twitter = "your-twitter-handle"
  linkedin = "your-linkedin-profile"

# Navigation menu
[[menu.main]]
  name = "Home"
  url = "/"
  weight = 1

[[menu.main]]
  name = "Posts"
  url = "/posts/"
  weight = 2

[[menu.main]]
  name = "About"
  url = "/about/"
  weight = 3

# Taxonomy configuration
[taxonomies]
  tag = "tags"
  category = "categories"
```

### Add Custom Styling

```bash
# Create custom CSS
mkdir -p templates/default/static/css
cat > templates/default/static/css/custom.css << 'EOF'
/* Custom site styling */
:root {
  --primary-color: #2563eb;
  --secondary-color: #64748b;
  --accent-color: #f59e0b;
}

.site-header {
  background: var(--primary-color);
  color: white;
  padding: 1rem 0;
}

.post-card {
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 1.5rem;
  margin-bottom: 1rem;
  transition: box-shadow 0.2s;
}

.post-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.tag {
  background: var(--accent-color);
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.875rem;
  margin-right: 0.5rem;
}
EOF
```

## Step 6: Add Interactive Components

### Enable Quiz Engine

```bash
# Update component configuration
nano templates/default/components.yml
```

**Add Quiz Engine:**
```yaml
components:
  - name: quiz-engine
    version: "1.0.0"
    enabled: true
    config:
      theme: "default"
      show_progress: true
      allow_retake: true
      show_correct_answers: true
```

### Create a Quiz

```bash
# Create quiz content
mkdir -p templates/default/content/quizzes
cat > templates/default/content/quizzes/web-basics.md << 'EOF'
---
title: "Web Development Basics Quiz"
description: "Test your knowledge of web development fundamentals"
quiz_data: "web-basics"
---

# Web Development Basics Quiz

Test your knowledge of HTML, CSS, and JavaScript fundamentals.

{{< quiz "web-basics" >}}
EOF

# Create quiz data
mkdir -p templates/default/data/quizzes
cat > templates/default/data/quizzes/web-basics.yml << 'EOF'
title: "Web Development Basics"
description: "Fundamental concepts in web development"
questions:
  - question: "What does HTML stand for?"
    type: "single-choice"
    options:
      - "Hypertext Markup Language"
      - "High Tech Modern Language"
      - "Home Tool Markup Language"
      - "Hyperlink and Text Markup Language"
    correct: 0
    explanation: "HTML stands for Hypertext Markup Language, which is the standard markup language for creating web pages."

  - question: "Which CSS property is used to change the text color?"
    type: "single-choice"
    options:
      - "font-color"
      - "text-color"
      - "color"
      - "foreground-color"
    correct: 2
    explanation: "The 'color' property in CSS is used to set the color of text."

  - question: "What are the three main technologies for frontend web development?"
    type: "multiple-choice"
    options:
      - "HTML"
      - "CSS"
      - "JavaScript"
      - "PHP"
      - "Python"
    correct: [0, 1, 2]
    explanation: "HTML, CSS, and JavaScript are the three fundamental technologies for frontend web development."
EOF
```

## Step 7: Build and Test

### Rebuild with Components

```bash
# Build with quiz engine
./scripts/build.sh \
  --template=default \
  --components=quiz-engine \
  --output=my-interactive-site \
  --verbose

# Verify quiz files are included
ls -la my-interactive-site/js/
ls -la my-interactive-site/quizzes/
```

### Test Interactive Features

```bash
# Start development server
cd my-interactive-site
python3 -m http.server 8000

# Open quiz page
open http://localhost:8000/quizzes/web-basics/
```

## Step 8: Optimize for Production

### Production Build

```bash
cd ../  # Return to project root

# Create optimized production build
./scripts/build.sh \
  --template=default \
  --components=quiz-engine \
  --environment=production \
  --minify \
  --base-url=https://yourdomain.com \
  --output=production-site
```

### Verify Optimization

```bash
# Check file sizes
du -sh production-site/*

# Verify minification
head production-site/css/style.css
head production-site/js/main.js

# Check for gzip compression
gzip -t production-site/css/*.css
gzip -t production-site/js/*.js
```

## Step 9: Deploy Your Site

### GitHub Pages (Free Hosting)

```bash
# Create GitHub repository
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/yourusername/your-repo.git
git push -u origin main

# Create deployment workflow
mkdir -p .github/workflows
```

**Create `.github/workflows/deploy.yml`:**
```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      with:
        submodules: recursive

    - name: Setup Build Environment
      uses: ./.github/actions/setup-build-env

    - name: Build site
      run: |
        ./scripts/build.sh \
          --template=default \
          --components=quiz-engine \
          --environment=production \
          --minify \
          --output=./dist

    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./dist
```

### Netlify (Drag and Drop)

```bash
# Build for Netlify
./scripts/build.sh \
  --template=default \
  --components=quiz-engine \
  --environment=production \
  --minify \
  --output=netlify-deploy

# Zip the output
zip -r site.zip netlify-deploy/

# Upload to netlify.com via drag-and-drop
echo "Upload site.zip to https://app.netlify.com/drop"
```

## Step 10: Next Steps

### Advanced Customization

1. **Custom Layouts**: Create custom Hugo layouts in `templates/your-template/layouts/`
2. **Advanced Components**: Explore component development
3. **Performance Optimization**: Implement caching and CDN
4. **SEO Enhancement**: Add structured data and meta tags

### Learning Resources

1. **Hugo Documentation**: [gohugo.io](https://gohugo.io/documentation/)
2. **Template Guide**: [Template Usage Guide](../user-guides/templates.md)
3. **Component Development**: [Component Development Guide](../developer-docs/components.md)
4. **Build System**: [Build System Guide](../user-guides/build-system.md)

### Community and Support

1. **GitHub Issues**: [Report bugs or request features](https://github.com/info-tech-io/hugo-templates/issues)
2. **Discussions**: [Join community discussions](https://github.com/info-tech-io/hugo-templates/discussions)
3. **Contributing**: [Contributing Guide](../developer-docs/contributing.md)

## Troubleshooting

### Common Issues

**Build Fails:**
```bash
# Run diagnostics
./scripts/diagnostic.js --verbose

# Validate configuration
./scripts/validate.js --template=default

# Check detailed logs
./scripts/build.sh --debug --verbose --template=default
```

**Missing Dependencies:**
```bash
# Reinstall dependencies
npm ci

# Update submodules
git submodule update --init --recursive

# Check system requirements
./scripts/diagnostic.js --system
```

**Theme Issues:**
```bash
# List available themes
./scripts/list.js --themes

# Verify theme structure
ls -la themes/compose/

# Test with minimal theme
./scripts/build.sh --template=minimal --theme=compose
```

### Getting Help

1. **Documentation**: Check [troubleshooting guides](../troubleshooting/)
2. **GitHub Issues**: Search existing issues or create new one
3. **Community**: Join discussions for help and tips
4. **Error Logs**: Always include full error logs when asking for help

## Summary

Congratulations! You've successfully:

✅ Installed the Hugo Template Factory Framework
✅ Created your first site with multiple templates
✅ Customized content and configuration
✅ Added interactive components
✅ Built optimized production sites
✅ Deployed to hosting platforms

You're now ready to create amazing static sites with Hugo Template Factory!

## What's Next?

- **Explore Advanced Templates**: Try the academic or enterprise templates
- **Build Custom Components**: Create your own interactive elements
- **Optimize Performance**: Learn advanced optimization techniques
- **Join the Community**: Contribute to the project and help others

## Related Documentation

- [Template Usage Guide](../user-guides/templates.md)
- [Build System Guide](../user-guides/build-system.md)
- [Component Development](../developer-docs/components.md)
- [Deployment Guide](../user-guides/deployment.md)