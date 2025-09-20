/**
 * Jest Configuration for Hugo Template Factory Framework
 * Stage 4.4 - CI/CD Setup and Automation
 */

module.exports = {
    // Test environment
    testEnvironment: 'node',

    // Test directories
    testMatch: [
        '<rootDir>/tests/**/*.test.js'
    ],

    // Setup files
    setupFilesAfterEnv: [
        '<rootDir>/tests/setup.js'
    ],

    // Coverage configuration
    collectCoverage: true,
    coverageDirectory: 'coverage',
    coverageReporters: ['text', 'lcov', 'html', 'json'],

    // Coverage collection patterns
    collectCoverageFrom: [
        'scripts/**/*.js',
        '!scripts/logger.js', // Exclude logger from coverage
        '!**/node_modules/**',
        '!coverage/**',
        '!tests/**'
    ],

    // Coverage thresholds
    coverageThreshold: {
        global: {
            branches: 70,
            functions: 75,
            lines: 80,
            statements: 80
        }
    },

    // Test timeout
    testTimeout: 120000, // 2 minutes for integration tests

    // Verbose output
    verbose: true,

    // Test result processor
    testResultsProcessor: '<rootDir>/tests/results-processor.js',

    // Module paths
    moduleDirectories: ['node_modules', 'scripts'],

    // File extensions
    moduleFileExtensions: ['js', 'json'],

    // Transform configuration
    transform: {},

    // Clear mocks between tests
    clearMocks: true,

    // Restore mocks after each test
    restoreMocks: true,

    // Error handling
    errorOnDeprecated: true,

    // Test name pattern
    testNamePattern: undefined,

    // Global setup and teardown
    globalSetup: '<rootDir>/tests/global-setup.js',
    globalTeardown: '<rootDir>/tests/global-teardown.js',

    // Custom matchers
    setupFilesAfterEnv: ['<rootDir>/tests/jest-matchers.js'],

    // Reporters
    reporters: [
        'default',
        ['jest-junit', {
            outputDirectory: 'test-results',
            outputName: 'junit.xml',
            classNameTemplate: '{classname}',
            titleTemplate: '{title}',
            ancestorSeparator: ' › ',
            usePathForSuiteName: 'true'
        }]
    ],

    // Max workers for parallel testing
    maxWorkers: '50%',

    // Test categories with different configurations
    projects: [
        {
            displayName: 'unit',
            testMatch: ['<rootDir>/tests/unit/**/*.test.js'],
            testTimeout: 30000
        },
        {
            displayName: 'integration',
            testMatch: ['<rootDir>/tests/integration/**/*.test.js'],
            testTimeout: 120000,
            setupFilesAfterEnv: ['<rootDir>/tests/integration-setup.js']
        },
        {
            displayName: 'performance',
            testMatch: ['<rootDir>/tests/performance/**/*.test.js'],
            testTimeout: 300000, // 5 minutes for performance tests
            setupFilesAfterEnv: ['<rootDir>/tests/performance-setup.js']
        }
    ],

    // Watch mode configuration
    watchPathIgnorePatterns: [
        '<rootDir>/node_modules/',
        '<rootDir>/coverage/',
        '<rootDir>/test-results/',
        '<rootDir>/test-build/'
    ],

    // Snapshot configuration
    snapshotSerializers: [],

    // Module mapping
    moduleNameMapping: {},

    // Ignore patterns
    testPathIgnorePatterns: [
        '<rootDir>/node_modules/',
        '<rootDir>/coverage/',
        '<rootDir>/test-build/'
    ],

    // Cache configuration
    cacheDirectory: '<rootDir>/.jest-cache',

    // Bail configuration (stop on first failure)
    bail: false,

    // Force exit
    forceExit: true,

    // Detect open handles
    detectOpenHandles: true,

    // Notify configuration
    notify: false,

    // Silent mode
    silent: false
};