/**
 * Jest Setup File
 * Hugo Template Factory Framework Test Setup
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

// Global test configuration
global.TEST_CONFIG = {
    projectRoot: path.join(__dirname, '..'),
    tempDir: path.join(os.tmpdir(), 'hugo-templates-jest-' + Date.now()),
    timeout: {
        unit: 30000,
        integration: 120000,
        performance: 300000
    }
};

// Setup global test utilities
global.testUtils = {
    createTempDir: (name = 'test') => {
        const tempPath = path.join(global.TEST_CONFIG.tempDir, name);
        if (!fs.existsSync(tempPath)) {
            fs.mkdirSync(tempPath, { recursive: true });
        }
        return tempPath;
    },

    cleanupTempDir: (dirPath) => {
        if (fs.existsSync(dirPath)) {
            fs.rmSync(dirPath, { recursive: true, force: true });
        }
    },

    fileExists: (filePath) => {
        return fs.existsSync(filePath);
    },

    readFile: (filePath) => {
        return fs.readFileSync(filePath, 'utf8');
    },

    writeFile: (filePath, content) => {
        const dir = path.dirname(filePath);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }
        fs.writeFileSync(filePath, content);
    }
};

// Setup test environment
beforeAll(() => {
    // Create main temp directory
    if (!fs.existsSync(global.TEST_CONFIG.tempDir)) {
        fs.mkdirSync(global.TEST_CONFIG.tempDir, { recursive: true });
    }

    // Set environment variables for testing
    process.env.NODE_ENV = 'test';
    process.env.HUGO_TEMPLATES_TEST = 'true';
});

afterAll(() => {
    // Cleanup temp directory
    if (fs.existsSync(global.TEST_CONFIG.tempDir)) {
        fs.rmSync(global.TEST_CONFIG.tempDir, { recursive: true, force: true });
    }
});

// Increase timeout for all tests
jest.setTimeout(120000);

// Console output control
const originalConsole = console;
global.console = {
    ...originalConsole,
    log: process.env.JEST_VERBOSE ? originalConsole.log : () => {},
    info: process.env.JEST_VERBOSE ? originalConsole.info : () => {},
    warn: originalConsole.warn,
    error: originalConsole.error
};

// Performance monitoring setup
global.performance = {
    mark: (name) => {
        global.performance.marks = global.performance.marks || {};
        global.performance.marks[name] = Date.now();
    },

    measure: (name, startMark, endMark) => {
        const marks = global.performance.marks || {};
        const start = marks[startMark] || 0;
        const end = marks[endMark] || Date.now();
        return end - start;
    }
};