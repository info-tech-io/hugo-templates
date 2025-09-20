/**
 * Integration Tests Setup
 * Hugo Template Factory Framework
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

// Setup for integration tests
beforeAll(() => {
    // Create integration test temp directory
    global.INTEGRATION_TEMP_DIR = path.join(os.tmpdir(), 'hugo-templates-integration-' + Date.now());

    if (!fs.existsSync(global.INTEGRATION_TEMP_DIR)) {
        fs.mkdirSync(global.INTEGRATION_TEMP_DIR, { recursive: true });
    }

    console.log('🔗 Integration tests setup completed');
});

afterAll(() => {
    // Cleanup integration test directory
    if (global.INTEGRATION_TEMP_DIR && fs.existsSync(global.INTEGRATION_TEMP_DIR)) {
        fs.rmSync(global.INTEGRATION_TEMP_DIR, { recursive: true, force: true });
    }

    console.log('🔗 Integration tests cleanup completed');
});