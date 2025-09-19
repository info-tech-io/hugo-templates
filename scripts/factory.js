#!/usr/bin/env node

/**
 * Hugo Template Factory Framework - Node.js Wrapper
 *
 * This script provides a Node.js wrapper around the bash build.sh script,
 * allowing integration with npm ecosystem while maintaining the dual interface approach.
 */

const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

// Script paths
const SCRIPT_DIR = __dirname;
const BUILD_SCRIPT = path.join(SCRIPT_DIR, 'build.sh');

/**
 * Check if bash script exists and is executable
 */
function validateBashScript() {
    if (!fs.existsSync(BUILD_SCRIPT)) {
        console.error('❌ Build script not found:', BUILD_SCRIPT);
        process.exit(1);
    }

    try {
        fs.accessSync(BUILD_SCRIPT, fs.constants.X_OK);
    } catch (error) {
        console.error('❌ Build script is not executable:', BUILD_SCRIPT);
        console.error('   Run: chmod +x', BUILD_SCRIPT);
        process.exit(1);
    }
}

/**
 * Check if running on a supported platform
 */
function validatePlatform() {
    const platform = os.platform();

    if (platform === 'win32') {
        console.error('❌ Windows is not currently supported for bash script execution');
        console.error('   Please use the Node.js CLI directly: npx hugo-templates build');
        process.exit(1);
    }

    // Check if bash is available
    try {
        execSync('which bash', { stdio: 'ignore' });
    } catch (error) {
        console.error('❌ Bash shell not found');
        console.error('   Please install bash or use the Node.js CLI directly');
        process.exit(1);
    }
}

/**
 * Execute the bash script with provided arguments
 * @param {string[]} args - Command line arguments
 */
function executeBashScript(args) {
    return new Promise((resolve, reject) => {
        // Spawn the bash script
        const child = spawn('bash', [BUILD_SCRIPT, ...args], {
            stdio: 'inherit', // Pass through stdin, stdout, stderr
            cwd: process.cwd()
        });

        child.on('close', (code) => {
            if (code === 0) {
                resolve(code);
            } else {
                reject(new Error(`Build script exited with code ${code}`));
            }
        });

        child.on('error', (error) => {
            reject(new Error(`Failed to start build script: ${error.message}`));
        });

        // Handle process termination signals
        process.on('SIGINT', () => {
            child.kill('SIGINT');
        });

        process.on('SIGTERM', () => {
            child.kill('SIGTERM');
        });
    });
}

/**
 * Show usage information
 */
function showUsage() {
    console.log(`
Usage: node factory.js [OPTIONS]

Hugo Template Factory Framework - Node.js Wrapper

This wrapper provides npm integration for the bash build script while
maintaining compatibility with the dual interface approach.

All options are passed through to the underlying bash script.
For detailed help, use: node factory.js --help

Examples:
    # Basic build
    node factory.js

    # Build with specific template
    node factory.js --template=minimal

    # Show bash script help
    node factory.js --help

    # Validate only
    node factory.js --validate-only

Note: This wrapper requires bash and is not supported on Windows.
      On Windows, use the Node.js CLI directly.
`);
}

/**
 * Process command line arguments
 * @param {string[]} args - Command line arguments
 */
function processArguments(args) {
    // Check for special cases
    if (args.length === 0) {
        // No arguments, just run the build script
        return args;
    }

    if (args.includes('--help') || args.includes('-h')) {
        // Help requested, pass through to bash script
        return args;
    }

    if (args.includes('--version') || args.includes('-V')) {
        // Version information
        try {
            const packageJson = require('../package.json');
            console.log(`Hugo Template Factory Framework v${packageJson.version}`);
            console.log('Node.js wrapper for bash build script');
            process.exit(0);
        } catch (error) {
            console.error('❌ Could not read package version');
            process.exit(1);
        }
    }

    if (args.includes('--wrapper-help')) {
        showUsage();
        process.exit(0);
    }

    // Pass all other arguments through to bash script
    return args;
}

/**
 * Main execution function
 */
async function main() {
    try {
        // Get command line arguments (skip node and script name)
        const args = process.argv.slice(2);

        // Process arguments
        const processedArgs = processArguments(args);

        // Validate platform and dependencies
        validatePlatform();
        validateBashScript();

        // Execute the bash script
        await executeBashScript(processedArgs);

        // Success
        process.exit(0);

    } catch (error) {
        console.error('❌ Wrapper execution failed:', error.message);
        process.exit(1);
    }
}

// Export for testing
module.exports = {
    validateBashScript,
    validatePlatform,
    executeBashScript,
    processArguments
};

// Run main function if this script is executed directly
if (require.main === module) {
    main().catch((error) => {
        console.error('❌ Unexpected error:', error);
        process.exit(1);
    });
}