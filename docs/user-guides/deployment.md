# Deployment Guide

## Overview

This guide covers deploying sites built with the Hugo Template Factory Framework to various hosting platforms and environments.

## Prerequisites

Before deploying, ensure you have:

- Successfully built your site using the build system
- Tested the site locally
- Configured production settings
- Set up necessary accounts for your chosen platform

## Quick Deployment

### Build for Production

```bash
# Production build with optimization
./scripts/build.sh \
  --template=default \
  --environment=production \
  --minify \
  --base-url=https://yourdomain.com \
  --output=./dist

# Verify build
ls -la ./dist/
```

## Deployment Platforms

### GitHub Pages

#### 1. Repository Setup

```bash
# Create deployment branch
git checkout -b gh-pages

# Add GitHub Pages workflow
mkdir -p .github/workflows
```

#### 2. GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4
      with:
        submodules: recursive
        fetch-depth: 0

    - name: Setup Build Environment
      uses: ./.github/actions/setup-build-env
      with:
        hugo-version: '0.148.0'
        node-version: '18'

    - name: Setup Pages
      id: pages
      uses: actions/configure-pages@v4

    - name: Build site
      run: |
        ./scripts/build.sh \
          --template=default \
          --environment=production \
          --minify \
          --base-url=${{ steps.pages.outputs.base_url }} \
          --output=./dist

    - name: Upload artifact
      uses: actions/upload-pages-artifact@v3
      with:
        path: ./dist

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
    - name: Deploy to GitHub Pages
      id: deployment
      uses: actions/deploy-pages@v4
```

#### 3. Repository Configuration

1. Go to Repository → Settings → Pages
2. Select "GitHub Actions" as source
3. Save configuration

### Netlify

#### 1. Manual Deployment

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Build site
./scripts/build.sh \
  --template=default \
  --environment=production \
  --minify \
  --base-url=https://yoursite.netlify.app \
  --output=./dist

# Deploy
netlify deploy --prod --dir=./dist
```

#### 2. Continuous Deployment

Create `netlify.toml`:

```toml
[build]
  publish = "dist"
  command = "./scripts/build.sh --template=default --environment=production --minify --output=./dist"

[build.environment]
  HUGO_VERSION = "0.148.0"
  NODE_VERSION = "18"

[[redirects]]
  from = "/*"
  to = "/404.html"
  status = 404

[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-XSS-Protection = "1; mode=block"
    X-Content-Type-Options = "nosniff"
```

#### 3. Repository Connection

1. Connect GitHub repository to Netlify
2. Set build command: `./scripts/build.sh --template=default --environment=production --minify --output=./dist`
3. Set publish directory: `dist`
4. Deploy

### Vercel

#### 1. Manual Deployment

```bash
# Install Vercel CLI
npm install -g vercel

# Build site
./scripts/build.sh \
  --template=default \
  --environment=production \
  --minify \
  --output=./dist

# Deploy
vercel --prod ./dist
```

#### 2. Continuous Deployment

Create `vercel.json`:

```json
{
  "version": 2,
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/static-build",
      "config": {
        "distDir": "dist"
      }
    }
  ],
  "buildCommand": "./scripts/build.sh --template=default --environment=production --minify --output=./dist",
  "devCommand": "hugo server --source=./build-temp",
  "outputDirectory": "dist"
}
```

Add to `package.json`:

```json
{
  "scripts": {
    "build": "./scripts/build.sh --template=default --environment=production --minify --output=./dist"
  }
}
```

### AWS S3 + CloudFront

#### 1. Build and Prepare

```bash
# Build for AWS
./scripts/build.sh \
  --template=default \
  --environment=production \
  --minify \
  --base-url=https://yourdomain.com \
  --output=./dist
```

#### 2. AWS CLI Deployment

```bash
# Install AWS CLI
pip install awscli

# Configure AWS credentials
aws configure

# Create S3 bucket
aws s3 mb s3://your-bucket-name

# Enable static website hosting
aws s3 website s3://your-bucket-name \
  --index-document index.html \
  --error-document 404.html

# Sync files
aws s3 sync ./dist s3://your-bucket-name --delete

# Set public read permissions
aws s3api put-bucket-policy \
  --bucket your-bucket-name \
  --policy file://bucket-policy.json
```

#### 3. Bucket Policy (bucket-policy.json)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::your-bucket-name/*"
    }
  ]
}
```

#### 4. CloudFront Distribution

```bash
# Create CloudFront distribution
aws cloudfront create-distribution \
  --distribution-config file://cloudfront-config.json
```

### Digital Ocean Apps

#### 1. App Specification

Create `.do/app.yaml`:

```yaml
name: hugo-site
services:
- name: web
  source_dir: /
  github:
    repo: your-username/your-repo
    branch: main
  run_command: ./scripts/build.sh --template=default --environment=production --minify --output=./dist
  build_command: |
    git submodule update --init --recursive
    npm ci
  environment_slug: ubuntu-18
  instance_count: 1
  instance_size_slug: basic-xxs
  routes:
  - path: /
  static_sites:
  - name: site
    source_dir: dist
    index_document: index.html
    error_document: 404.html
```

### Custom Server Deployment

#### 1. Nginx Configuration

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    # SSL configuration
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # Root directory
    root /var/www/hugo-site;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Handle Hugo's pretty URLs
    location / {
        try_files $uri $uri/ =404;
    }

    # Custom 404 page
    error_page 404 /404.html;
}
```

#### 2. Deployment Script

```bash
#!/bin/bash
# deploy.sh

set -e

echo "🚀 Starting deployment..."

# Build site
./scripts/build.sh \
  --template=default \
  --environment=production \
  --minify \
  --base-url=https://yourdomain.com \
  --output=./dist

# Backup current site
sudo cp -r /var/www/hugo-site /var/www/hugo-site-backup-$(date +%Y%m%d-%H%M%S)

# Deploy new version
sudo rsync -av --delete ./dist/ /var/www/hugo-site/

# Reload nginx
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Deployment completed successfully!"
```

## Environment Configuration

### Production Settings

#### Hugo Configuration (hugo.toml)

```toml
# Production-specific settings
baseURL = "https://yourdomain.com"
canonifyURLs = true
relativeURLs = false

# SEO optimization
[params]
  description = "Site description for SEO"
  keywords = ["keyword1", "keyword2"]
  author = "Author Name"

# Minification
[minify]
  disableCSS = false
  disableHTML = false
  disableJS = false
  disableJSON = false
  disableSVG = false
  disableXML = false

# Security
[security]
  [security.exec]
    allow = ["^dart-sass-embedded$", "^go$", "^npx$", "^postcss$"]
  [security.funcs]
    getenv = ["^HUGO_"]
```

#### Component Configuration (components.yml)

```yaml
components:
  - name: analytics
    version: "1.0.0"
    enabled: true
    config:
      provider: "google"
      tracking_id: "GA-XXXXXXXXX"
      anonymize_ip: true

  - name: quiz-engine
    version: "1.0.0"
    enabled: true
    config:
      cdn_url: "https://cdn.yourdomain.com"
      cache_duration: "24h"
```

### Environment Variables

```bash
# Production environment variables
export HUGO_ENV=production
export HUGO_BASEURL=https://yourdomain.com
export HUGO_ENABLEGITINFO=true

# Component configuration
export ANALYTICS_ID=GA-XXXXXXXXX
export CDN_URL=https://cdn.yourdomain.com
```

## CI/CD Deployment

### GitHub Actions Complete Workflow

```yaml
name: Build and Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  NODE_VERSION: '18'
  HUGO_VERSION: '0.148.0'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      with:
        submodules: recursive

    - name: Setup Build Environment
      uses: ./.github/actions/setup-build-env
      with:
        hugo-version: ${{ env.HUGO_VERSION }}
        node-version: ${{ env.NODE_VERSION }}

    - name: Run tests
      run: |
        npm run test
        ./scripts/validate.js --all

    - name: Test build
      run: |
        ./scripts/build.sh --template=default --validate-only

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v4
      with:
        submodules: recursive

    - name: Setup Build Environment
      uses: ./.github/actions/setup-build-env
      with:
        hugo-version: ${{ env.HUGO_VERSION }}
        node-version: ${{ env.NODE_VERSION }}

    - name: Build for production
      run: |
        ./scripts/build.sh \
          --template=default \
          --environment=production \
          --minify \
          --base-url=https://yourdomain.com \
          --output=./dist

    - name: Deploy to staging
      run: |
        # Deploy to staging environment
        rsync -avz --delete ./dist/ staging-server:/var/www/staging/

    - name: Run smoke tests
      run: |
        curl -f https://staging.yourdomain.com || exit 1

    - name: Deploy to production
      run: |
        # Deploy to production
        rsync -avz --delete ./dist/ production-server:/var/www/production/
```

## Performance Optimization

### Build Optimization

```bash
# Optimized production build
./scripts/build.sh \
  --template=default \
  --environment=production \
  --minify \
  --no-draft \
  --no-future \
  --base-url=https://yourdomain.com \
  --output=./dist

# Enable build caching
export HUGO_CACHEDIR="$HOME/.hugo-cache"
```

### Asset Optimization

```bash
# Compress images before deployment
find ./dist -name "*.jpg" -exec jpegoptim --max=85 {} \;
find ./dist -name "*.png" -exec optipng -o2 {} \;

# Generate WebP versions
find ./dist -name "*.jpg" -exec cwebp -q 80 {} -o {}.webp \;
```

### CDN Configuration

```toml
# hugo.toml CDN settings
[params]
  cdn_url = "https://cdn.yourdomain.com"
  asset_version = "v1.2.3"

# Use CDN for static assets
[markup]
  [markup.goldmark]
    [markup.goldmark.renderer]
      unsafe = true
```

## Monitoring and Maintenance

### Health Checks

```bash
#!/bin/bash
# health-check.sh

URL="https://yourdomain.com"

# Check site availability
if curl -f -s $URL > /dev/null; then
    echo "✅ Site is accessible"
else
    echo "❌ Site is down"
    exit 1
fi

# Check page load time
LOAD_TIME=$(curl -o /dev/null -s -w "%{time_total}" $URL)
if (( $(echo "$LOAD_TIME < 3.0" | bc -l) )); then
    echo "✅ Load time: ${LOAD_TIME}s"
else
    echo "⚠️ Slow load time: ${LOAD_TIME}s"
fi
```

### Backup Strategy

```bash
#!/bin/bash
# backup.sh

DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/backups/hugo-site-$DATE"

# Create backup
mkdir -p $BACKUP_DIR
cp -r ./dist $BACKUP_DIR/
tar -czf "$BACKUP_DIR.tar.gz" $BACKUP_DIR

# Clean old backups (keep last 7 days)
find /backups -name "hugo-site-*.tar.gz" -mtime +7 -delete
```

## Troubleshooting Deployment

### Common Issues

#### Build Failures

```bash
# Debug build issues
./scripts/build.sh --debug --verbose --template=default

# Check Hugo configuration
hugo config --source=./templates/default

# Validate all components
./scripts/validate.js --all
```

#### Deployment Errors

```bash
# Check file permissions
ls -la ./dist/
chmod -R 644 ./dist/*
find ./dist -type d -exec chmod 755 {} \;

# Verify all files are present
find ./dist -name "index.html"
find ./dist -name "*.css"
find ./dist -name "*.js"
```

### Performance Issues

```bash
# Analyze bundle size
du -sh ./dist/*
find ./dist -size +1M

# Check for optimization
gzip -t ./dist/css/*.css
gzip -t ./dist/js/*.js
```

## Security Considerations

### HTTPS Configuration

- Always use HTTPS in production
- Configure proper SSL certificates
- Enable HSTS headers
- Use secure cipher suites

### Content Security Policy

```html
<!-- Add to head section -->
<meta http-equiv="Content-Security-Policy"
      content="default-src 'self';
               script-src 'self' 'unsafe-inline' https://www.google-analytics.com;
               style-src 'self' 'unsafe-inline';
               img-src 'self' data: https:;">
```

### Security Headers

```nginx
# Nginx security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

## Related Documentation

- [Build System Guide](./build-system.md)
- [Performance Optimization](../troubleshooting/performance.md)
- [GitHub Actions Guide](../developer-docs/github-actions.md)
- [Template Usage Guide](./templates.md)