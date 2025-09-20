/**
 * Jest Global Setup
 * Hugo Template Factory Framework
 */

const fs = require('fs');
const path = require('path');

module.exports = async () => {
    console.log('🏗️ Setting up Hugo Template Factory Framework tests...');

    // Ensure test directories exist
    const testDirs = [
        path.join(__dirname, '../test-results'),
        path.join(__dirname, '../coverage')
    ];

    testDirs.forEach(dir => {
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
    });

    // Set global test environment
    process.env.NODE_ENV = 'test';
    process.env.HUGO_TEMPLATES_TEST = 'true';

    console.log('✅ Global test setup completed');
};