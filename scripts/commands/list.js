const chalk = require('chalk');
const fs = require('fs-extra');
const path = require('path');

/**
 * List command implementation
 * @param {string} type - Type of items to list
 * @param {Object} options - Command options
 */
async function listCommand(type, options) {
  console.log(chalk.blue('📋 Hugo Template Factory - Available Items'));
  console.log(chalk.gray('━'.repeat(50)));

  try {
    const results = {};

    if (type === 'all' || type === 'templates') {
      results.templates = await getTemplates(options.verbose);
    }

    if (type === 'all' || type === 'themes') {
      results.themes = await getThemes(options.verbose);
    }

    if (type === 'all' || type === 'components') {
      results.components = await getComponents(options.verbose);
    }

    // Output results in requested format
    switch (options.format) {
      case 'json':
        console.log(JSON.stringify(results, null, 2));
        break;
      case 'yaml':
        const yaml = require('yaml');
        console.log(yaml.stringify(results));
        break;
      case 'plain':
        outputPlain(results, type);
        break;
      default:
        outputTable(results, type, options.verbose);
    }

  } catch (error) {
    console.error(chalk.red('❌ List failed:'));
    console.error(chalk.red(`   ${error.message}`));
    process.exit(1);
  }
}

/**
 * Get available templates
 */
async function getTemplates(verbose) {
  const templatesDir = path.join(__dirname, '../../templates');
  const templates = [];

  if (await fs.pathExists(templatesDir)) {
    const items = await fs.readdir(templatesDir);
    for (const item of items) {
      const itemPath = path.join(templatesDir, item);
      const stat = await fs.stat(itemPath);
      if (stat.isDirectory()) {
        const template = { name: item, status: 'available' };

        if (verbose) {
          const configPath = path.join(itemPath, 'template.json');
          if (await fs.pathExists(configPath)) {
            const config = await fs.readJson(configPath);
            template.description = config.description;
            template.version = config.version;
          }
        }

        templates.push(template);
      }
    }
  }

  return templates;
}

/**
 * Get available themes
 */
async function getThemes(verbose) {
  const themesDir = path.join(__dirname, '../../themes');
  const themes = [];

  if (await fs.pathExists(themesDir)) {
    const items = await fs.readdir(themesDir);
    for (const item of items) {
      const itemPath = path.join(themesDir, item);
      const stat = await fs.stat(itemPath);
      if (stat.isDirectory()) {
        const theme = { name: item, status: 'available' };

        if (verbose) {
          const configPath = path.join(itemPath, 'theme.toml');
          if (await fs.pathExists(configPath)) {
            // Could parse theme.toml for more details
            theme.description = 'Hugo theme';
          }
        }

        themes.push(theme);
      }
    }
  }

  return themes;
}

/**
 * Get available components
 */
async function getComponents(verbose) {
  const componentsDir = path.join(__dirname, '../../components');
  const components = [];

  if (await fs.pathExists(componentsDir)) {
    const items = await fs.readdir(componentsDir);
    for (const item of items) {
      const itemPath = path.join(componentsDir, item);
      const stat = await fs.stat(itemPath);
      if (stat.isDirectory()) {
        const component = { name: item, status: 'available' };

        if (verbose) {
          const configPath = path.join(itemPath, 'component.json');
          if (await fs.pathExists(configPath)) {
            const config = await fs.readJson(configPath);
            component.description = config.description;
            component.version = config.version;
            component.status = config.status;
          }
        }

        components.push(component);
      }
    }
  }

  return components;
}

/**
 * Output results as table
 */
function outputTable(results, type, verbose) {
  Object.keys(results).forEach(category => {
    if (results[category].length === 0) return;

    console.log(chalk.yellow(`\n${category.toUpperCase()}:`));
    results[category].forEach(item => {
      console.log(chalk.white(`  • ${item.name}`));
      if (verbose && item.description) {
        console.log(chalk.gray(`    ${item.description}`));
      }
      if (verbose && item.version) {
        console.log(chalk.gray(`    Version: ${item.version}`));
      }
      if (verbose && item.status && item.status !== 'available') {
        console.log(chalk.gray(`    Status: ${item.status}`));
      }
    });
  });
}

/**
 * Output results as plain text
 */
function outputPlain(results, type) {
  Object.keys(results).forEach(category => {
    results[category].forEach(item => {
      console.log(item.name);
    });
  });
}

module.exports = listCommand;