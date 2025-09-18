#!/usr/bin/env node

/**
 * Hugo Template Factory Framework CLI
 * The first parametrized scaffolding tool for Hugo ecosystem
 */

const { program } = require('commander');
const chalk = require('chalk');
const path = require('path');
const fs = require('fs-extra');

// Import command handlers
const buildCommand = require('../scripts/commands/build');
const listCommand = require('../scripts/commands/list');
const validateCommand = require('../scripts/commands/validate');
const initCommand = require('../scripts/commands/init');

// Package info
const packageJson = require('../package.json');

// Configure program
program
  .name('hugo-templates')
  .description('Hugo Template Factory Framework - Parametrized scaffolding for Hugo')
  .version(packageJson.version, '-V, --version', 'output the current version')
  .helpOption('-h, --help', 'display help for command');

// Build command
program
  .command('build')
  .alias('b')
  .description('Build a Hugo site with specified template, theme and components')
  .option('-t, --template <template>', 'template to use', 'default')
  .option('--theme <theme>', 'Hugo theme to apply', 'compose')
  .option('-c, --components <components...>', 'components to include')
  .option('-o, --output <path>', 'output directory', './site')
  .option('--config <path>', 'path to custom configuration file')
  .option('--minify', 'enable Hugo minification')
  .option('--draft', 'include draft content')
  .option('--future', 'include future content')
  .option('--base-url <url>', 'base URL for the site')
  .option('-e, --environment <env>', 'Hugo environment', 'development')
  .option('-v, --verbose', 'enable verbose output')
  .option('--log-level <level>', 'log level', 'info')
  .action(buildCommand);

// List command
program
  .command('list')
  .alias('ls')
  .description('List available templates, themes or components')
  .argument('[type]', 'type of items to list (templates|themes|components|all)', 'all')
  .option('-f, --format <format>', 'output format (table|json|yaml|plain)', 'table')
  .option('-v, --verbose', 'show detailed information')
  .action(listCommand);

// Validate command
program
  .command('validate')
  .alias('v')
  .description('Validate configuration files and templates')
  .argument('[target]', 'target to validate', '.')
  .option('-t, --type <type>', 'validation type (config|template|component|all)', 'all')
  .option('--strict', 'enable strict validation mode')
  .option('--fix', 'attempt to fix validation errors automatically')
  .action(validateCommand);

// Init command
program
  .command('init')
  .alias('i')
  .description('Initialize a new Hugo project with interactive prompts')
  .argument('[name]', 'project name')
  .option('-t, --template <template>', 'template to use')
  .option('--theme <theme>', 'Hugo theme to apply')
  .option('-c, --components <components...>', 'components to include')
  .option('--no-interactive', 'skip interactive prompts')
  .action(initCommand);

// Global error handler
program.configureOutput({
  writeErr: (str) => process.stderr.write(chalk.red(str))
});

// Handle unknown commands
program.on('command:*', () => {
  console.error(chalk.red(`Invalid command: ${program.args.join(' ')}`));
  console.log(chalk.yellow('Use --help to see available commands'));
  process.exit(1);
});

// Parse arguments
if (process.argv.length === 2) {
  program.help();
}

program.parse();