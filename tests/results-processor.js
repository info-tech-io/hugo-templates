/**
 * Jest Test Results Processor
 * Hugo Template Factory Framework - Stage 4.4
 */

const fs = require('fs');
const path = require('path');

/**
 * Process and enhance Jest test results
 */
module.exports = (results) => {
    // Create results directory if it doesn't exist
    const resultsDir = path.join(__dirname, '..', 'test-results');
    if (!fs.existsSync(resultsDir)) {
        fs.mkdirSync(resultsDir, { recursive: true });
    }

    // Enhanced results with additional metrics
    const enhancedResults = {
        ...results,
        timestamp: new Date().toISOString(),
        environment: {
            nodeVersion: process.version,
            platform: process.platform,
            arch: process.arch,
            ci: process.env.CI === 'true',
            github: process.env.GITHUB_ACTIONS === 'true'
        },
        summary: {
            totalTests: results.numTotalTests,
            passedTests: results.numPassedTests,
            failedTests: results.numFailedTests,
            skippedTests: results.numPendingTests,
            totalTestSuites: results.numTotalTestSuites,
            passedTestSuites: results.numPassedTestSuites,
            failedTestSuites: results.numFailedTestSuites,
            testDuration: results.testResults.reduce((total, suite) =>
                total + (suite.perfStats?.end - suite.perfStats?.start || 0), 0
            ),
            coverageThresholdMet: results.coverageMap ?
                checkCoverageThresholds(results.coverageMap) : null
        },
        performance: {
            slowestTests: getSlowTests(results.testResults, 5),
            fastestTests: getFastTests(results.testResults, 5),
            averageTestDuration: calculateAverageTestDuration(results.testResults)
        },
        categories: categorizeTests(results.testResults)
    };

    // Write enhanced results
    const resultsPath = path.join(resultsDir, 'test-results.json');
    fs.writeFileSync(resultsPath, JSON.stringify(enhancedResults, null, 2));

    // Write summary report
    const summaryPath = path.join(resultsDir, 'test-summary.md');
    fs.writeFileSync(summaryPath, generateMarkdownSummary(enhancedResults));

    // Write performance report
    const perfPath = path.join(resultsDir, 'performance-report.json');
    fs.writeFileSync(perfPath, JSON.stringify(enhancedResults.performance, null, 2));

    // Console output
    console.log('\n=== TEST RESULTS SUMMARY ===');
    console.log(`Total Tests: ${enhancedResults.summary.totalTests}`);
    console.log(`Passed: ${enhancedResults.summary.passedTests}`);
    console.log(`Failed: ${enhancedResults.summary.failedTests}`);
    console.log(`Skipped: ${enhancedResults.summary.skippedTests}`);
    console.log(`Success Rate: ${(enhancedResults.summary.passedTests / enhancedResults.summary.totalTests * 100).toFixed(2)}%`);
    console.log(`Total Duration: ${(enhancedResults.summary.testDuration / 1000).toFixed(2)}s`);

    if (enhancedResults.summary.failedTests > 0) {
        console.log('\n=== FAILED TESTS ===');
        enhancedResults.testResults.forEach(suite => {
            suite.testResults.forEach(test => {
                if (test.status === 'failed') {
                    console.log(`❌ ${suite.testFilePath}: ${test.fullName}`);
                    if (test.failureMessages && test.failureMessages.length > 0) {
                        console.log(`   ${test.failureMessages[0].split('\n')[0]}`);
                    }
                }
            });
        });
    }

    return results;
};

/**
 * Check if coverage thresholds are met
 */
function checkCoverageThresholds(coverageMap) {
    // This would need the actual coverage threshold configuration
    return true; // Placeholder
}

/**
 * Get slowest tests
 */
function getSlowTests(testResults, count) {
    const allTests = [];

    testResults.forEach(suite => {
        suite.testResults.forEach(test => {
            if (test.duration) {
                allTests.push({
                    name: test.fullName,
                    file: suite.testFilePath,
                    duration: test.duration
                });
            }
        });
    });

    return allTests
        .sort((a, b) => b.duration - a.duration)
        .slice(0, count);
}

/**
 * Get fastest tests
 */
function getFastTests(testResults, count) {
    const allTests = [];

    testResults.forEach(suite => {
        suite.testResults.forEach(test => {
            if (test.duration) {
                allTests.push({
                    name: test.fullName,
                    file: suite.testFilePath,
                    duration: test.duration
                });
            }
        });
    });

    return allTests
        .sort((a, b) => a.duration - b.duration)
        .slice(0, count);
}

/**
 * Calculate average test duration
 */
function calculateAverageTestDuration(testResults) {
    let totalDuration = 0;
    let testCount = 0;

    testResults.forEach(suite => {
        suite.testResults.forEach(test => {
            if (test.duration) {
                totalDuration += test.duration;
                testCount++;
            }
        });
    });

    return testCount > 0 ? totalDuration / testCount : 0;
}

/**
 * Categorize tests by type
 */
function categorizeTests(testResults) {
    const categories = {
        unit: { passed: 0, failed: 0, total: 0 },
        integration: { passed: 0, failed: 0, total: 0 },
        performance: { passed: 0, failed: 0, total: 0 }
    };

    testResults.forEach(suite => {
        let category = 'unit';
        if (suite.testFilePath.includes('/integration/')) {
            category = 'integration';
        } else if (suite.testFilePath.includes('/performance/')) {
            category = 'performance';
        }

        suite.testResults.forEach(test => {
            categories[category].total++;
            if (test.status === 'passed') {
                categories[category].passed++;
            } else if (test.status === 'failed') {
                categories[category].failed++;
            }
        });
    });

    return categories;
}

/**
 * Generate markdown summary
 */
function generateMarkdownSummary(results) {
    return `# Test Results Summary

**Generated:** ${results.timestamp}
**Environment:** ${results.environment.platform} (${results.environment.arch})
**Node.js:** ${results.environment.nodeVersion}
**CI:** ${results.environment.ci ? 'Yes' : 'No'}

## Overall Results

| Metric | Value |
|--------|-------|
| Total Tests | ${results.summary.totalTests} |
| Passed | ${results.summary.passedTests} |
| Failed | ${results.summary.failedTests} |
| Skipped | ${results.summary.skippedTests} |
| Success Rate | ${(results.summary.passedTests / results.summary.totalTests * 100).toFixed(2)}% |
| Total Duration | ${(results.summary.testDuration / 1000).toFixed(2)}s |

## Test Categories

| Category | Passed | Failed | Total | Success Rate |
|----------|--------|--------|-------|--------------|
| Unit | ${results.categories.unit.passed} | ${results.categories.unit.failed} | ${results.categories.unit.total} | ${results.categories.unit.total > 0 ? (results.categories.unit.passed / results.categories.unit.total * 100).toFixed(2) : 0}% |
| Integration | ${results.categories.integration.passed} | ${results.categories.integration.failed} | ${results.categories.integration.total} | ${results.categories.integration.total > 0 ? (results.categories.integration.passed / results.categories.integration.total * 100).toFixed(2) : 0}% |
| Performance | ${results.categories.performance.passed} | ${results.categories.performance.failed} | ${results.categories.performance.total} | ${results.categories.performance.total > 0 ? (results.categories.performance.passed / results.categories.performance.total * 100).toFixed(2) : 0}% |

## Performance Metrics

**Average Test Duration:** ${results.performance.averageTestDuration.toFixed(2)}ms

### Slowest Tests
${results.performance.slowestTests.map(test =>
    `- ${test.name} (${test.duration}ms)`
).join('\n')}

### Fastest Tests
${results.performance.fastestTests.map(test =>
    `- ${test.name} (${test.duration}ms)`
).join('\n')}

---

*Generated by Hugo Template Factory Framework Test Suite*
`;
}