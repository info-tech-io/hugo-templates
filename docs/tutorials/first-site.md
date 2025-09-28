# Your First Site Tutorial

## Overview

This focused tutorial helps you create your very first site with the Hugo Template Factory Framework in under 15 minutes. Perfect for complete beginners who want to see results quickly.

## What You'll Build

A simple personal website with:
- Homepage with your introduction
- About page
- Contact information
- Professional styling

## Prerequisites

- No prior experience needed
- Computer with internet connection
- 15 minutes of your time

## Step 1: Quick Setup (2 minutes)

### Install and Clone

```bash
# Clone the project
git clone https://github.com/info-tech-io/hugo-templates.git
cd hugo-templates

# Quick setup
git submodule update --init --recursive
npm ci
```

### Verify Everything Works

```bash
# This should show green checkmarks
./scripts/diagnostic.js --all
```

**If you see errors**, check the [Installation Guide](../user-guides/installation.md) for help.

## Step 2: Create Your Site (3 minutes)

### Choose Your Template

For your first site, we'll use the `minimal` template - it's fast and simple:

```bash
# Create your site
./scripts/build.sh --template=minimal --output=my-website

# Look at what was created
ls -la my-website/
```

**You should see:**
```
my-website/
├── index.html      # Your homepage
├── about/
│   └── index.html  # About page
├── css/           # Stylesheets
├── js/            # JavaScript
└── images/        # Images
```

### Preview Your Site

```bash
# Start a local server
cd my-website
python3 -m http.server 8000

# Open in your browser
# Go to: http://localhost:8000
```

🎉 **Congratulations!** You now have a working website!

## Step 3: Personalize Your Content (5 minutes)

### Edit Your Homepage

```bash
# Go back to the project
cd ../

# Edit the homepage content
nano templates/minimal/content/_index.md
```

**Replace the content with:**
```markdown
---
title: "Welcome to My Website"
description: "Personal website of [Your Name]"
---

# Hello, I'm [Your Name]

Welcome to my personal website! I'm passionate about [your interests/profession].

## What I Do

I'm a [your profession/role] who loves [your hobbies/interests]. I created this website to share my thoughts and connect with like-minded people.

## My Interests

- [Interest 1]
- [Interest 2]
- [Interest 3]

## Get in Touch

Feel free to reach out if you'd like to connect!

[Contact information or social links]
```

### Update Your About Page

```bash
nano templates/minimal/content/about.md
```

**Replace with:**
```markdown
---
title: "About Me"
---

# About Me

## My Story

[Write a brief story about yourself - your background, what you're passionate about, what you're working on]

## My Journey

[Share your professional or personal journey]

## What I'm Up To Now

[Current projects, goals, or activities]

## Fun Facts

- [Fun fact 1]
- [Fun fact 2]
- [Fun fact 3]

## Let's Connect

I'd love to hear from you! You can reach me at:

- Email: [your-email@example.com]
- [Social media links]
```

### Customize Site Settings

```bash
nano templates/minimal/hugo.toml
```

**Update these important settings:**
```toml
title = "Your Name - Personal Website"

[params]
  description = "Personal website of [Your Name]"
  author = "Your Name"

  # Add your social links (optional)
  email = "your.email@example.com"
  github = "your-github-username"
  twitter = "your-twitter-handle"
  linkedin = "your-linkedin-profile"
```

## Step 4: Rebuild and Preview (2 minutes)

### Rebuild Your Site

```bash
# Rebuild with your changes
./scripts/build.sh --template=minimal --output=my-website
```

### See Your Changes

```bash
# Start the server again
cd my-website
python3 -m http.server 8000

# Refresh your browser at http://localhost:8000
```

**You should now see your personalized content!**

## Step 5: Make It Look Better (3 minutes)

### Add a Profile Photo

```bash
# Add your photo (copy your photo file to this location)
cp /path/to/your/photo.jpg templates/minimal/static/images/profile.jpg

# Reference it in your homepage
nano templates/minimal/content/_index.md
```

**Add to your homepage:**
```markdown
# Hello, I'm [Your Name]

![Profile Photo](/images/profile.jpg)

Welcome to my personal website! I'm passionate about [your interests/profession].
```

### Custom Colors (Optional)

```bash
# Create custom CSS
nano templates/minimal/static/css/custom.css
```

**Add your favorite colors:**
```css
/* Custom colors for your site */
:root {
  --main-color: #3b82f6;     /* Blue - change to your favorite */
  --accent-color: #10b981;   /* Green - change to your favorite */
}

/* Apply to headers */
h1, h2, h3 {
  color: var(--main-color);
}

/* Apply to links */
a {
  color: var(--accent-color);
}

/* Style your profile photo */
img[alt="Profile Photo"] {
  border-radius: 50%;
  width: 200px;
  height: 200px;
  object-fit: cover;
  margin: 1rem 0;
}
```

### Rebuild One More Time

```bash
cd ../  # Go back to project root
./scripts/build.sh --template=minimal --output=my-website
```

## Step 6: Share Your Site (Optional)

### Option A: Netlify (Easiest)

1. Go to [netlify.com](https://netlify.com)
2. Sign up for free
3. Drag and drop your `my-website` folder
4. Get your live URL instantly!

### Option B: GitHub Pages

```bash
# Create GitHub repository
git init
git add .
git commit -m "My first website"

# Push to GitHub (create repository first on github.com)
git remote add origin https://github.com/yourusername/my-website.git
git push -u origin main

# Enable GitHub Pages in repository settings
```

Your site will be live at: `https://yourusername.github.io/my-website`

## Common Customizations

### Add More Pages

```bash
# Create a projects page
mkdir -p templates/minimal/content/projects
cat > templates/minimal/content/projects/_index.md << 'EOF'
---
title: "My Projects"
---

# My Projects

Here are some projects I've worked on:

## Project 1
Description of your first project.

## Project 2
Description of your second project.
EOF
```

### Add Navigation Menu

```bash
nano templates/minimal/hugo.toml
```

**Add menu configuration:**
```toml
# Add navigation menu
[[menu.main]]
  name = "Home"
  url = "/"
  weight = 1

[[menu.main]]
  name = "About"
  url = "/about/"
  weight = 2

[[menu.main]]
  name = "Projects"
  url = "/projects/"
  weight = 3
```

### Change Fonts

```bash
nano templates/minimal/static/css/custom.css
```

**Add font changes:**
```css
/* Import Google Fonts */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');

/* Apply new font */
body {
  font-family: 'Inter', sans-serif;
}
```

## Troubleshooting

### Site Doesn't Load?

```bash
# Check if files exist
ls -la my-website/index.html

# Try different port
python3 -m http.server 8080
# Then go to http://localhost:8080
```

### Build Errors?

```bash
# Check what went wrong
./scripts/build.sh --template=minimal --debug --verbose

# Validate your content
./scripts/validate.js --template=minimal
```

### Content Not Showing?

```bash
# Check your markdown syntax
cat templates/minimal/content/_index.md

# Make sure you have proper frontmatter (lines with ---)
```

## Next Steps

Now that you have your first site, you might want to:

### Learn More
- **[Getting Started Tutorial](./getting-started.md)** - Comprehensive tutorial with advanced features
- **[Template Guide](../user-guides/templates.md)** - Learn about all available templates
- **[Build System Guide](../user-guides/build-system.md)** - Understand the build process

### Add Cool Features
- **Blog Posts**: Add a blog section to share your thoughts
- **Interactive Quizzes**: Use the quiz engine component
- **Contact Forms**: Add ways for people to reach you
- **Photo Galleries**: Showcase your work or hobbies

### Make It Professional
- **Custom Domain**: Get your own domain name
- **Analytics**: Track your visitors
- **SEO**: Optimize for search engines
- **Performance**: Make it load super fast

## Success Stories

**"I created my first website in 10 minutes and deployed it to Netlify. It looks professional and I'm so proud of it!"** - Sarah, Designer

**"The Hugo Template Factory made it so easy. I was intimidated by web development, but this tutorial made it approachable."** - Mike, Teacher

## Get Help

- **Stuck?** Check the [Troubleshooting Guide](../troubleshooting/common-issues.md)
- **Need help?** Ask in [GitHub Discussions](https://github.com/info-tech-io/hugo-templates/discussions)
- **Found a bug?** Report it in [GitHub Issues](https://github.com/info-tech-io/hugo-templates/issues)

## Summary

🎉 **You did it!** In just 15 minutes, you:

✅ Set up the Hugo Template Factory Framework
✅ Created your first website
✅ Personalized it with your content
✅ Learned basic customization
✅ (Optional) Deployed it online

**Your website is live and you're officially a website owner!**

## What Makes This Special?

Unlike other website builders, you now have:
- **Complete control** over your site
- **No monthly fees** for hosting
- **Professional-quality** output
- **Skills** you can build upon
- **Source code** you fully own

Welcome to the world of web development! 🚀

## Related Documentation

- [Getting Started Tutorial](./getting-started.md) - More comprehensive tutorial
- [Template Usage Guide](../user-guides/templates.md) - Explore all templates
- [Deployment Guide](../user-guides/deployment.md) - Advanced deployment options
- [Build System Guide](../user-guides/build-system.md) - Understand the build process