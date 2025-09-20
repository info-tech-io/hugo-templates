/**
 * Custom Jest Matchers
 * Hugo Template Factory Framework
 */

const fs = require('fs');
const path = require('path');

// Custom matcher for file existence
expect.extend({
    toExistAsFile(received) {
        const pass = fs.existsSync(received) && fs.statSync(received).isFile();

        if (pass) {
            return {
                message: () => `expected ${received} not to exist as a file`,
                pass: true
            };
        } else {
            return {
                message: () => `expected ${received} to exist as a file`,
                pass: false
            };
        }
    },

    toExistAsDirectory(received) {
        const pass = fs.existsSync(received) && fs.statSync(received).isDirectory();

        if (pass) {
            return {
                message: () => `expected ${received} not to exist as a directory`,
                pass: true
            };
        } else {
            return {
                message: () => `expected ${received} to exist as a directory`,
                pass: false
            };
        }
    },

    toContainFiles(received, expected) {
        if (!fs.existsSync(received) || !fs.statSync(received).isDirectory()) {
            return {
                message: () => `expected ${received} to be a directory`,
                pass: false
            };
        }

        const files = fs.readdirSync(received);
        const missingFiles = expected.filter(file => !files.includes(file));

        if (missingFiles.length === 0) {
            return {
                message: () => `expected ${received} not to contain files: ${expected.join(', ')}`,
                pass: true
            };
        } else {
            return {
                message: () => `expected ${received} to contain files: ${missingFiles.join(', ')}`,
                pass: false
            };
        }
    },

    toHaveValidJsonContent(received) {
        if (!fs.existsSync(received)) {
            return {
                message: () => `expected ${received} to exist`,
                pass: false
            };
        }

        try {
            const content = fs.readFileSync(received, 'utf8');
            JSON.parse(content);
            return {
                message: () => `expected ${received} not to have valid JSON content`,
                pass: true
            };
        } catch (error) {
            return {
                message: () => `expected ${received} to have valid JSON content, but got: ${error.message}`,
                pass: false
            };
        }
    },

    toHaveValidTomlContent(received) {
        if (!fs.existsSync(received)) {
            return {
                message: () => `expected ${received} to exist`,
                pass: false
            };
        }

        const content = fs.readFileSync(received, 'utf8');

        // Basic TOML validation (check for common patterns)
        const hasValidStructure = content.includes('=') &&
                                 !content.includes('[[[') &&
                                 !content.includes(']]]');

        if (hasValidStructure) {
            return {
                message: () => `expected ${received} not to have valid TOML content`,
                pass: true
            };
        } else {
            return {
                message: () => `expected ${received} to have valid TOML content`,
                pass: false
            };
        }
    },

    toCompleteWithinTime(received, expectedTime) {
        if (typeof received !== 'number') {
            return {
                message: () => `expected duration to be a number, got ${typeof received}`,
                pass: false
            };
        }

        const pass = received <= expectedTime;

        if (pass) {
            return {
                message: () => `expected operation not to complete within ${expectedTime}ms, but completed in ${received}ms`,
                pass: true
            };
        } else {
            return {
                message: () => `expected operation to complete within ${expectedTime}ms, but took ${received}ms`,
                pass: false
            };
        }
    },

    toHaveSuccessfulOutput(received) {
        const successIndicators = ['SUCCESS', '✓', 'completed', 'finished', 'done'];
        const errorIndicators = ['ERROR', '✗', 'failed', 'error'];

        const hasSuccess = successIndicators.some(indicator =>
            received.toUpperCase().includes(indicator.toUpperCase())
        );
        const hasError = errorIndicators.some(indicator =>
            received.toUpperCase().includes(indicator.toUpperCase())
        );

        const pass = hasSuccess && !hasError;

        if (pass) {
            return {
                message: () => `expected output not to indicate success`,
                pass: true
            };
        } else {
            return {
                message: () => `expected output to indicate success, got: ${received.slice(0, 200)}...`,
                pass: false
            };
        }
    },

    toBeExecutableFile(received) {
        if (!fs.existsSync(received)) {
            return {
                message: () => `expected ${received} to exist`,
                pass: false
            };
        }

        const stats = fs.statSync(received);
        const isExecutable = stats.mode & parseInt('111', 8);

        if (isExecutable) {
            return {
                message: () => `expected ${received} not to be executable`,
                pass: true
            };
        } else {
            return {
                message: () => `expected ${received} to be executable`,
                pass: false
            };
        }
    },

    toHaveFileSize(received, expectedSize, tolerance = 0.1) {
        if (!fs.existsSync(received)) {
            return {
                message: () => `expected ${received} to exist`,
                pass: false
            };
        }

        const actualSize = fs.statSync(received).size;
        const diff = Math.abs(actualSize - expectedSize);
        const maxDiff = expectedSize * tolerance;
        const pass = diff <= maxDiff;

        if (pass) {
            return {
                message: () => `expected ${received} not to have size around ${expectedSize} bytes (±${tolerance * 100}%), but was ${actualSize} bytes`,
                pass: true
            };
        } else {
            return {
                message: () => `expected ${received} to have size around ${expectedSize} bytes (±${tolerance * 100}%), but was ${actualSize} bytes`,
                pass: false
            };
        }
    },

    toMatchHugoConfigPattern(received) {
        if (!fs.existsSync(received)) {
            return {
                message: () => `expected ${received} to exist`,
                pass: false
            };
        }

        const content = fs.readFileSync(received, 'utf8');
        const requiredFields = ['baseURL', 'title'];
        const hasAllFields = requiredFields.every(field =>
            content.includes(field)
        );

        if (hasAllFields) {
            return {
                message: () => `expected ${received} not to match Hugo config pattern`,
                pass: true
            };
        } else {
            const missingFields = requiredFields.filter(field => !content.includes(field));
            return {
                message: () => `expected ${received} to match Hugo config pattern, missing: ${missingFields.join(', ')}`,
                pass: false
            };
        }
    }
});