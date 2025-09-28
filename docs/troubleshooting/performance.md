# Performance Troubleshooting Guide

## Overview

This guide helps you diagnose and resolve performance issues in the Hugo Template Factory Framework, including slow build times, high memory usage, and optimization strategies.

## Performance Metrics

### Build Time Benchmarks

| Template | Expected Build Time | Memory Usage | Optimized Build Time |
|----------|-------------------|--------------|---------------------|
| minimal | < 30 seconds | < 512MB | < 15 seconds |
| default | < 2 minutes | < 1GB | < 1 minute |
| academic | < 3 minutes | < 1.5GB | < 90 seconds |
| enterprise | < 5 minutes | < 2GB | < 2.5 minutes |

### Performance Indicators

**Good Performance:**
- Build time under expected benchmarks
- Memory usage stable and within limits
- No timeout errors
- Responsive during build process

**Poor Performance:**
- Build time exceeding 2x expected benchmarks
- Memory usage growing continuously
- Frequent timeout or out-of-memory errors
- System becomes unresponsive

## Diagnostic Commands

### Performance Profiling

```bash
# Profile build performance
time ./scripts/build.sh --template=default --verbose

# Hugo build metrics
hugo --templateMetrics --source=./build-directory

# Memory usage monitoring
./scripts/build.sh --debug --verbose --template=enterprise 2>&1 | grep -i memory

# System resource usage
htop  # or top on basic systems
iotop  # for disk I/O monitoring
```

### Build Analysis

```bash
# Analyze build components
./scripts/diagnostic.js --verbose --log-file=performance.log

# Check template complexity
find templates/ -name "*.html" -exec wc -l {} \; | sort -n

# Content analysis
find content/ -name "*.md" -exec wc -l {} \; | sort -n
du -sh content/*
```

## Common Performance Issues

### 1. Slow Build Times

#### Symptoms
- Build takes longer than 5 minutes
- CPU usage consistently high
- Build appears to hang

#### Diagnosis
```bash
# Profile the build process
time ./scripts/build.sh --template=default --verbose

# Check for large files
find content/ static/ -size +10M -ls

# Analyze template complexity
grep -r "range\|where\|sort" layouts/ | wc -l
```

#### Solutions

**1. Use Minimal Template for Development**
```bash
# Fast development builds
./scripts/build.sh --template=minimal --environment=development

# Production builds only when needed
./scripts/build.sh --template=enterprise --environment=production --minify
```

**2. Enable Caching**
```bash
# Set Hugo cache directory
export HUGO_CACHEDIR="$HOME/.hugo-cache"

# Verify cache is working
ls -la $HOME/.hugo-cache/
```

**3. Optimize Content Structure**
```bash
# Split large content directories
mkdir content/posts/2023 content/posts/2024
mv content/posts/old-*.md content/posts/2023/

# Remove unused large files
find static/ -name "*.jpg" -size +1M -delete
find static/ -name "*.pdf" -size +5M -delete
```

**4. Disable Unnecessary Features**
```bash
# Development builds without minification
./scripts/build.sh --no-minify --environment=development

# Skip draft content
./scripts/build.sh --no-draft

# Disable future content
./scripts/build.sh --no-future
```

### 2. High Memory Usage

#### Symptoms
```
fatal error: runtime: out of memory
runtime: out of memory: cannot allocate
```

#### Diagnosis
```bash
# Monitor memory during build
./scripts/build.sh --debug 2>&1 | grep -i "memory\|alloc"

# Check system memory
free -h
cat /proc/meminfo | grep -i available
```

#### Solutions

**1. Increase Memory Limits**
```bash
# Set Hugo memory limit (in MB)
export HUGO_MAXMEMORY=2048

# For very large sites
export HUGO_MAXMEMORY=4096
```

**2. Process Content in Batches**
```bash
# Split large content directories
mkdir content/batch1 content/batch2
mv content/posts/[a-m]*.md content/batch1/
mv content/posts/[n-z]*.md content/batch2/

# Build batches separately
./scripts/build.sh --content=content/batch1 --output=output/batch1
./scripts/build.sh --content=content/batch2 --output=output/batch2
```

**3. Optimize Images and Assets**
```bash
# Compress large images
find static/ -name "*.jpg" -size +500k -exec jpegoptim --max=85 {} \;
find static/ -name "*.png" -size +500k -exec optipng -o2 {} \;

# Use WebP format for better compression
for img in static/images/*.jpg; do
    cwebp -q 80 "$img" -o "${img%.jpg}.webp"
done
```

### 3. Slow CI/CD Performance

#### Symptoms
- GitHub Actions taking longer than 10 minutes
- Frequent timeouts in CI/CD
- High runner costs

#### Diagnosis
```bash
# Check workflow performance
gh run list --limit 10 --json conclusion,createdAt,updatedAt

# Analyze individual jobs
gh run view <run-id> --log
```

#### Solutions

**1. Optimize GitHub Actions**
```yaml
# Use our optimized setup action
- name: Setup Build Environment
  uses: ./.github/actions/setup-build-env
  with:
    hugo-version: '0.148.0'
    node-version: '18'

# Enable smart caching
- name: Cache Hugo Build
  uses: actions/cache@v3
  with:
    path: |
      ~/.hugo-cache
      ./resources
    key: hugo-${{ runner.os }}-${{ hashFiles('**/hugo.toml') }}
```

**2. Parallel Job Execution**
```yaml
strategy:
  matrix:
    test-type: [unit, integration, performance]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - name: Run ${{ matrix.test-type }} tests
      run: npm run test:${{ matrix.test-type }}
```

**3. Conditional Execution**
```yaml
# Only run on relevant changes
on:
  push:
    paths:
      - 'scripts/**'
      - 'templates/**'
      - 'content/**'
```

### 4. Large Asset Optimization

#### Symptoms
- Build output size exceeding 100MB
- Slow site loading times
- High bandwidth usage

#### Diagnosis
```bash
# Analyze build output size
du -sh ./site/*
find ./site -size +1M -ls

# Check asset compression
gzip -t ./site/static/js/*.js 2>/dev/null || echo "No compression"
```

#### Solutions

**1. Enable Hugo Minification**
```bash
# Production builds with minification
./scripts/build.sh --minify --environment=production
```

**2. Optimize Static Assets**
```bash
# Compress JavaScript
npm install -g terser
find static/js -name "*.js" -exec terser {} -o {}.min.js \;

# Compress CSS
npm install -g clean-css-cli
find static/css -name "*.css" -exec cleancss -o {}.min.css {} \;
```

**3. Image Optimization**
```bash
# Install optimization tools
sudo apt-get install jpegoptim optipng

# Optimize all images
find static/ -name "*.jpg" -exec jpegoptim --max=85 {} \;
find static/ -name "*.png" -exec optipng -o2 {} \;
```

## Performance Optimization Strategies

### 1. Template Optimization

**Efficient Template Patterns:**
```html
<!-- Good: Use where instead of multiple conditions -->
{{ range where .Site.Pages "Type" "post" }}
  {{ .Title }}
{{ end }}

<!-- Avoid: Multiple nested ranges -->
{{ range .Site.Pages }}
  {{ if eq .Type "post" }}
    {{ .Title }}
  {{ end }}
{{ end }}
```

**Cache Expensive Operations:**
```html
<!-- Cache complex calculations -->
{{ $posts := where .Site.Pages "Type" "post" }}
{{ $recentPosts := first 10 $posts }}
{{ range $recentPosts }}
  {{ .Title }}
{{ end }}
```

### 2. Content Structure Optimization

**Efficient Content Organization:**
```
content/
├── posts/
│   ├── 2023/
│   │   └── monthly-archives/
│   └── 2024/
│       └── monthly-archives/
├── pages/
└── static/
    ├── images/
    │   ├── thumbs/      # Thumbnails
    │   └── full/        # Full-size images
    └── assets/
```

**Content Metadata Optimization:**
```yaml
---
title: "Post Title"
date: 2024-01-01
draft: false
tags: ["tag1", "tag2"]  # Limit to 3-5 tags
categories: ["main-category"]  # Single category
summary: "Brief summary under 160 characters"
---
```

### 3. Build Process Optimization

**Development vs Production Builds:**
```bash
# Development: Fast builds
./scripts/build.sh \
  --template=minimal \
  --environment=development \
  --no-minify

# Production: Optimized builds
./scripts/build.sh \
  --template=enterprise \
  --environment=production \
  --minify \
  --base-url=https://example.com
```

**Incremental Builds:**
```bash
# Only rebuild changed content
hugo --ignoreCache=false --source=./build-directory

# Use Hugo's built-in caching
export HUGO_CACHEDIR="$HOME/.hugo-cache"
```

## Performance Monitoring

### Automated Performance Testing

```bash
# Create performance test script
cat > scripts/perf-test.sh << 'EOF'
#!/bin/bash
echo "🚀 Performance Test Started"

# Record start time
start_time=$(date +%s)

# Run build
./scripts/build.sh --template=default --quiet

# Calculate duration
end_time=$(date +%s)
duration=$((end_time - start_time))

# Check results
if [ $duration -gt 120 ]; then
    echo "❌ Build too slow: ${duration}s (expected < 120s)"
    exit 1
else
    echo "✅ Build completed in ${duration}s"
fi
EOF

chmod +x scripts/perf-test.sh
```

### Continuous Performance Monitoring

```yaml
# .github/workflows/performance.yml
name: Performance Monitoring

on:
  push:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 0'  # Weekly

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Setup Build Environment
      uses: ./.github/actions/setup-build-env

    - name: Run Performance Tests
      run: |
        ./scripts/perf-test.sh

    - name: Report Results
      if: failure()
      run: |
        echo "::warning::Performance degradation detected"
```

## Troubleshooting Specific Scenarios

### Large Content Sites (1000+ Pages)

**Optimization Strategy:**
1. Use pagination for large lists
2. Implement content archives by year/month
3. Use Hugo's built-in caching
4. Consider static search instead of real-time

**Example Configuration:**
```toml
# hugo.toml
[pagination]
  pagerSize = 20

[caches]
  [caches.getjson]
    maxAge = "10m"
  [caches.getcsv]
    maxAge = "10m"
```

### Multi-Language Sites

**Performance Considerations:**
```toml
# hugo.toml
defaultContentLanguage = "en"
defaultContentLanguageInSubdir = false

[languages]
  [languages.en]
    weight = 1
    title = "English Site"
  [languages.ru]
    weight = 2
    title = "Russian Site"
```

### Complex Component Integration

**Efficient Component Loading:**
```yaml
# components.yml
components:
  - name: quiz-engine
    lazy_load: true  # Load only when needed
    cache_duration: "24h"
  - name: analytics
    defer: true  # Load after page content
```

## Emergency Performance Fixes

### Quick Fixes for Critical Performance Issues

1. **Switch to Minimal Template:**
```bash
./scripts/build.sh --template=minimal --output=emergency-build
```

2. **Disable Heavy Components:**
```bash
./scripts/build.sh --no-components --template=default
```

3. **Use Development Mode:**
```bash
./scripts/build.sh --environment=development --no-minify
```

4. **Clear All Caches:**
```bash
rm -rf ~/.hugo-cache/
rm -rf ./resources/
rm -rf ./public/
```

## Performance Best Practices

### 1. Regular Monitoring
- Run performance tests before major releases
- Monitor build times in CI/CD
- Track site loading speeds
- Profile memory usage regularly

### 2. Proactive Optimization
- Optimize images before adding to repository
- Structure content efficiently from start
- Use appropriate templates for different environments
- Implement caching strategies early

### 3. Scalability Planning
- Plan for content growth
- Design efficient template hierarchies
- Consider CDN integration for static assets
- Implement progressive loading strategies

## Related Documentation

- [Build System Guide](../user-guides/build-system.md)
- [Common Issues Guide](./common-issues.md)
- [GitHub Actions Guide](../developer-docs/github-actions.md)
- [Component Development](../developer-docs/components.md)