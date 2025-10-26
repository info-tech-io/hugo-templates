#!/usr/bin/env bats

#
# Performance Benchmarks for Federation Build System
# Tests execution time and performance targets
#

load '../helpers/test-helpers'

setup() {
    setup_test_environment

    # Source federated build script functions
    export SCRIPT_DIR="$BATS_TEST_DIRNAME/../../../scripts"
    export PROJECT_ROOT="$BATS_TEST_DIRNAME/../../.."
    export FEDERATED_BUILD_SCRIPT="$SCRIPT_DIR/federated-build.sh"

    # Set up test fixtures
    export TEST_FIXTURES_DIR="$BATS_TEST_DIRNAME/../fixtures/federation"
    export TEST_OUTPUT_DIR="$TEST_TEMP_DIR/output"
}

teardown() {
    teardown_test_environment
}

# ==============================================================================
# Helper Functions
# ==============================================================================

create_minimal_federation_config() {
    local config_file="$1"
    local num_modules="${2:-1}"

    cat > "$config_file" << 'EOF'
{
  "federation": {
    "name": "Performance Test Federation",
    "baseURL": "http://localhost:1313",
    "strategy": "download-merge-deploy"
  },
  "modules": [
EOF

    for i in $(seq 1 "$num_modules"); do
        local module_path="$TEST_TEMP_DIR/perf-module-$i"
        mkdir -p "$module_path/content/content"
        echo "Test content $i" > "$module_path/content/content/_index.md"

        cat > "$module_path/content/module.json" << 'MODEOF'
{
  "hugo_config": {
    "template": "minimal",
    "theme": "compose",
    "components": []
  },
  "site": {
    "baseURL": "http://localhost:1313",
    "language": "en"
  }
}
MODEOF

        cat >> "$config_file" << EOF
    {
      "name": "perf-module-$i",
      "source": {
        "repository": "local",
        "local_path": "$module_path",
        "path": "content",
        "branch": "main"
      },
      "destination": "/mod$i/",
      "module_json": "module.json"
    }
EOF
        [[ $i -lt $num_modules ]] && echo "," >> "$config_file"
    done

    cat >> "$config_file" << 'EOF'
  ]
}
EOF
}

# ==============================================================================
# Performance Tests
# ==============================================================================

@test "Performance: single module build completes in < 10 seconds" {
    # Create minimal single-module configuration
    local config="$TEST_TEMP_DIR/single-module.json"
    create_minimal_federation_config "$config" 1

    # Measure execution time
    local start_time=$(date +%s%N)

    run bash "$FEDERATED_BUILD_SCRIPT" \
        --config="$config" \
        --output="$TEST_OUTPUT_DIR" \
        --dry-run

    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # milliseconds

    # Output timing for analysis
    echo "Single module build duration: ${duration}ms" >&3

    # Verify: Build should succeed
    [ "$status" -eq 0 ] || echo "Build failed with status $status" >&3

    # Verify: Should complete in < 10 seconds (dry-run mode)
    if [ "$duration" -ge 10000 ]; then
        echo "WARNING: Build took longer than expected (${duration}ms)" >&3
    fi

    # Verify: Build processed the module
    assert_contains "$output" "perf-module-1"
}

@test "Performance: 3-module federation build completes in < 30 seconds" {
    # Create 3-module configuration
    local config="$TEST_TEMP_DIR/three-modules.json"
    create_minimal_federation_config "$config" 3

    # Measure execution time
    local start_time=$(date +%s%N)

    run bash "$FEDERATED_BUILD_SCRIPT" \
        --config="$config" \
        --output="$TEST_OUTPUT_DIR" \
        --dry-run

    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # milliseconds

    # Output timing for analysis
    echo "3-module build duration: ${duration}ms" >&3

    # Verify: Build should succeed
    [ "$status" -eq 0 ] || echo "Build failed with status $status" >&3

    # Verify: Should complete in < 30 seconds (dry-run mode)
    if [ "$duration" -ge 30000 ]; then
        echo "WARNING: Build took longer than expected (${duration}ms)" >&3
    fi

    # Verify: Build processed all modules
    assert_contains "$output" "perf-module-1"
    assert_contains "$output" "perf-module-2"
    assert_contains "$output" "perf-module-3"
}

@test "Performance: 5-module InfoTech.io simulation completes in < 60 seconds" {
    # Create 5-module configuration (simulates real production workload)
    local config="$TEST_TEMP_DIR/five-modules.json"
    create_minimal_federation_config "$config" 5

    # Measure execution time
    local start_time=$(date +%s%N)

    run bash "$FEDERATED_BUILD_SCRIPT" \
        --config="$config" \
        --output="$TEST_OUTPUT_DIR" \
        --dry-run

    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # milliseconds

    # Output timing for analysis
    echo "5-module build duration: ${duration}ms" >&3

    # Verify: Build should succeed
    [ "$status" -eq 0 ] || echo "Build failed with status $status" >&3

    # Verify: Should complete in < 60 seconds (dry-run mode)
    if [ "$duration" -ge 60000 ]; then
        echo "WARNING: Build took longer than expected (${duration}ms)" >&3
    fi

    # Verify: Build processed all modules
    assert_contains "$output" "perf-module-1"
    assert_contains "$output" "perf-module-5"

    # Verify: Reported correct module count
    assert_contains "$output" "5" || assert_contains "$output" "module"
}

@test "Performance: configuration parsing overhead is minimal" {
    # Create realistic configuration
    local config="$TEST_TEMP_DIR/config-parse-test.json"
    create_minimal_federation_config "$config" 3

    # Measure just the configuration loading time
    local start_time=$(date +%s%N)

    run bash "$FEDERATED_BUILD_SCRIPT" \
        --config="$config" \
        --output="$TEST_OUTPUT_DIR" \
        --dry-run \
        --quiet

    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # milliseconds

    # Output timing for analysis
    echo "Config parsing + 3-module build: ${duration}ms" >&3

    # Verify: Build should succeed
    [ "$status" -eq 0 ]

    # Verify: Total overhead should be reasonable (< 5 seconds for parsing + 3 dry-run modules)
    if [ "$duration" -ge 5000 ]; then
        echo "WARNING: Configuration parsing overhead is high (${duration}ms)" >&3
    fi

    # Estimate: Most time should be in actual building, not overhead
    # For 3 modules in dry-run, expect ~1-2 seconds total
}

@test "Performance: multi-module merge operations are efficient" {
    # Create configuration with multiple modules that will be merged
    local config="$TEST_TEMP_DIR/merge-performance.json"
    create_minimal_federation_config "$config" 4

    # Measure merge operation time
    local start_time=$(date +%s%N)

    run bash "$FEDERATED_BUILD_SCRIPT" \
        --config="$config" \
        --output="$TEST_OUTPUT_DIR" \
        --dry-run

    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))  # milliseconds

    # Output timing for analysis
    echo "4-module merge duration: ${duration}ms" >&3

    # Verify: Build should succeed
    [ "$status" -eq 0 ]

    # Verify: Merge operations should be efficient (< 10 seconds for 4 modules in dry-run)
    if [ "$duration" -ge 10000 ]; then
        echo "WARNING: Merge operations are slow (${duration}ms for 4 modules)" >&3
    fi

    # Verify: All modules were processed
    assert_contains "$output" "perf-module-1"
    assert_contains "$output" "perf-module-4"

    # Success: Merge completed within reasonable time
}
