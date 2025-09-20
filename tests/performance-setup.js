/**
 * Performance Tests Setup
 * Hugo Template Factory Framework
 */

const fs = require('fs');
const path = require('path');

// Setup for performance tests
beforeAll(() => {
    // Initialize performance monitoring
    global.PERFORMANCE_RESULTS = {};
    global.PERFORMANCE_START_TIME = Date.now();

    console.log('⚡ Performance tests setup completed');
});

afterAll(() => {
    // Save performance results
    const resultsDir = path.join(__dirname, '../test-results');
    if (!fs.existsSync(resultsDir)) {
        fs.mkdirSync(resultsDir, { recursive: true });
    }

    const perfResultsPath = path.join(resultsDir, 'performance-results.json');
    fs.writeFileSync(perfResultsPath, JSON.stringify({
        ...global.PERFORMANCE_RESULTS,
        totalTestTime: Date.now() - global.PERFORMANCE_START_TIME,
        timestamp: new Date().toISOString()
    }, null, 2));

    console.log('⚡ Performance tests cleanup completed');
});