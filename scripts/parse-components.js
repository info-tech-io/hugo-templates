#!/usr/bin/env node

/**
 * YAML Components Parser for Hugo Template Factory Framework
 * Parses components.yml files and provides component information
 */

const fs = require('fs');
const path = require('path');
const yaml = require('yaml');

/**
 * Parse components.yml file and output component information
 * @param {string} filePath - Path to components.yml file
 */
function parseComponents(filePath) {
    try {
        if (!fs.existsSync(filePath)) {
            console.log(`Components file not found: ${filePath}`);
            return;
        }

        const content = fs.readFileSync(filePath, 'utf8');
        const config = yaml.parse(content);

        if (!config || !config.components) {
            console.log('No components found in configuration');
            return;
        }

        console.log(`Template: ${config.template?.name || 'unknown'} (${config.template?.version || 'unknown'})`);
        console.log(`Description: ${config.template?.description || 'No description'}`);
        console.log('');
        console.log('Components:');

        Object.entries(config.components).forEach(([name, component]) => {
            const status = component.status || 'unknown';
            const version = component.version || 'unknown';
            const description = component.description || 'No description';

            const statusIcon = {
                'stable': '✅',
                'planned': '📋',
                'experimental': '🧪',
                'deprecated': '❌'
            }[status] || '❓';

            console.log(`  ${statusIcon} ${name} (${version}) - ${status}`);
            console.log(`     ${description}`);

            if (component.submodule_path) {
                console.log(`     Submodule: ${component.submodule_path}`);
            }

            if (component.static_files && component.static_files.length > 0) {
                console.log(`     Static files: ${component.static_files.join(', ')}`);
            }

            console.log('');
        });

        // Show Hugo configuration if present
        if (config.hugo) {
            console.log('Hugo Configuration:');
            console.log(`  Min version: ${config.hugo.minVersion || 'not specified'}`);
            console.log(`  Extended: ${config.hugo.extended || false}`);
            console.log('');
        }

        // Show build configuration if present
        if (config.build) {
            console.log('Build Configuration:');
            Object.entries(config.build).forEach(([key, value]) => {
                console.log(`  ${key}: ${value}`);
            });
            console.log('');
        }

    } catch (error) {
        console.error(`Error parsing components file: ${error.message}`);
        process.exit(1);
    }
}

// Main execution
if (require.main === module) {
    const filePath = process.argv[2];

    if (!filePath) {
        console.error('Usage: node parse-components.js <path-to-components.yml>');
        process.exit(1);
    }

    parseComponents(filePath);
}

module.exports = { parseComponents };