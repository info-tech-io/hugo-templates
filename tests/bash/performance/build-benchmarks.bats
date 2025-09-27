#!/usr/bin/env bats

#
# Performance Benchmarks for Build System
# Tests performance characteristics and regression detection
#

load '../helpers/test-helpers'

setup() {
    setup_test_environment

    export SCRIPT_DIR="$BATS_TEST_DIRNAME/../../../scripts"
    export PROJECT_ROOT="$BATS_TEST_DIRNAME/../../.."
    export TEST_OUTPUT_DIR="$TEST_TEMP_DIR/output"

    # Create comprehensive test environment for performance testing
    create_performance_test_environment
}

teardown() {
    teardown_test_environment
}

create_performance_test_environment() {
    # Create multiple templates for performance testing
    create_test_template_structure "$PROJECT_ROOT/templates" "corporate"
    create_test_template_structure "$PROJECT_ROOT/templates" "minimal"
    create_test_template_structure "$PROJECT_ROOT/templates" "educational"

    # Create themes
    mkdir -p "$PROJECT_ROOT/themes/compose"
    mkdir -p "$PROJECT_ROOT/themes/minimal"

    # Create various sized configuration files
    create_test_module_config "$TEST_TEMP_DIR/small_config.json" "minimal" "minimal"
    create_test_module_config "$TEST_TEMP_DIR/medium_config.json" "corporate" "compose"
    create_large_config_file "$TEST_TEMP_DIR/large_config.json"
}

create_large_config_file() {
    local config_file="$1"
    cat > "$config_file" << 'EOF'
{
  "hugo_config": {
    "template": "corporate",
    "theme": "compose",
    "components": [
      "quiz-engine",
      "analytics",
      "search",
      "auth",
      "comments",
      "newsletter",
      "social-share",
      "seo-optimizer"
    ]
  },
  "site": {
    "baseURL": "https://example.com",
    "language": "en",
    "title": "Large Test Site",
    "description": "A comprehensive test site with many components"
  },
  "build": {
    "environment": "production",
    "optimization": true,
    "minify": true,
    "bundling": true
  },
  "content": {
    "sections": [
      "blog", "docs", "products", "about", "contact",
      "tutorials", "guides", "api", "examples", "faq"
    ],
    "taxonomies": ["tags", "categories", "authors", "topics"],
    "languages": ["en", "es", "fr", "de", "it"]
  }
}
EOF
}

@test "performance benchmark: minimal template build time" {
    local duration_ms
    duration_ms=$(time_command "$SCRIPT_DIR/build.sh --template minimal --output $TEST_OUTPUT_DIR --force")

    # Minimal template should build quickly (under 5 seconds)
    assert_performance_threshold "$duration_ms" 5000 "minimal template build"

    echo "# Minimal template build time: ${duration_ms}ms" >&3
}

@test "performance benchmark: corporate template build time" {
    local duration_ms
    duration_ms=$(time_command "$SCRIPT_DIR/build.sh --template corporate --output $TEST_OUTPUT_DIR --force")

    # Corporate template should build within reasonable time (under 10 seconds)
    assert_performance_threshold "$duration_ms" 10000 "corporate template build"

    echo "# Corporate template build time: ${duration_ms}ms" >&3
}

@test "performance benchmark: validation-only mode speed" {
    local duration_ms
    duration_ms=$(time_command "$SCRIPT_DIR/build.sh --template corporate --validate-only")

    # Validation should be very fast (under 1 second)
    assert_performance_threshold "$duration_ms" 1000 "validation-only mode"

    echo "# Validation-only mode time: ${duration_ms}ms" >&3
}

@test "performance benchmark: module.json parsing speed" {
    local duration_ms
    duration_ms=$(time_command "$SCRIPT_DIR/build.sh --config $TEST_TEMP_DIR/small_config.json --validate-only")

    # Config parsing should be fast (under 500ms)
    assert_performance_threshold "$duration_ms" 500 "module.json parsing"

    echo "# Module.json parsing time: ${duration_ms}ms" >&3
}

@test "performance benchmark: large configuration processing" {
    local duration_ms
    duration_ms=$(time_command "$SCRIPT_DIR/build.sh --config $TEST_TEMP_DIR/large_config.json --validate-only")

    # Large config should still parse quickly (under 2 seconds)
    assert_performance_threshold "$duration_ms" 2000 "large configuration processing"

    echo "# Large config processing time: ${duration_ms}ms" >&3
}

@test "performance benchmark: error handling overhead" {
    # Measure normal execution
    local normal_duration
    normal_duration=$(time_command "$SCRIPT_DIR/build.sh --template corporate --validate-only")

    # Measure execution with debug mode (more error handling)
    local debug_duration
    debug_duration=$(time_command "$SCRIPT_DIR/build.sh --template corporate --validate-only --debug")

    # Debug mode shouldn't add more than 50% overhead
    local overhead_threshold=$((normal_duration * 150 / 100))
    assert_performance_threshold "$debug_duration" "$overhead_threshold" "error handling debug mode overhead"

    echo "# Normal validation: ${normal_duration}ms, Debug mode: ${debug_duration}ms" >&3
}

@test "performance benchmark: concurrent build capacity" {
    # Test multiple concurrent builds
    local start_time=$(date +%s%N)

    # Start 3 concurrent builds
    "$SCRIPT_DIR/build.sh" --template minimal --output "$TEST_TEMP_DIR/concurrent1" --force &
    local pid1=$!
    "$SCRIPT_DIR/build.sh" --template corporate --output "$TEST_TEMP_DIR/concurrent2" --force &
    local pid2=$!
    "$SCRIPT_DIR/build.sh" --template minimal --output "$TEST_TEMP_DIR/concurrent3" --force &
    local pid3=$!

    # Wait for all to complete
    wait $pid1; local status1=$?
    wait $pid2; local status2=$?
    wait $pid3; local status3=$?

    local end_time=$(date +%s%N)
    local total_duration=$(( (end_time - start_time) / 1000000 ))

    # All should succeed
    [ "$status1" -eq 0 ]
    [ "$status2" -eq 0 ]
    [ "$status3" -eq 0 ]

    # Concurrent execution should complete within reasonable time (under 30 seconds)
    assert_performance_threshold "$total_duration" 30000 "concurrent builds"

    echo "# Concurrent builds total time: ${total_duration}ms" >&3
}

@test "performance benchmark: memory usage efficiency" {
    # This is a conceptual test - actual memory monitoring depends on available tools
    # We'll test that the build doesn't leave behind large temporary files

    local temp_size_before=$(du -sb "$TEST_TEMP_DIR" | cut -f1)

    run "$SCRIPT_DIR/build.sh" --template corporate --output "$TEST_OUTPUT_DIR" --force
    [ "$status" -eq 0 ]

    local temp_size_after=$(du -sb "$TEST_TEMP_DIR" | cut -f1)
    local temp_growth=$((temp_size_after - temp_size_before))

    # Temporary file growth should be reasonable (under 100MB for our test)
    local max_temp_growth=$((100 * 1024 * 1024))  # 100MB
    [ "$temp_growth" -lt "$max_temp_growth" ]

    echo "# Temporary storage growth: ${temp_growth} bytes" >&3
}

@test "performance benchmark: help command responsiveness" {
    local duration_ms
    duration_ms=$(time_command "$SCRIPT_DIR/build.sh --help")

    # Help should be instant (under 100ms)
    assert_performance_threshold "$duration_ms" 100 "help command"

    echo "# Help command time: ${duration_ms}ms" >&3
}

@test "performance benchmark: parameter validation speed" {
    # Test with various parameter combinations
    local validations=(
        "--template corporate --validate-only"
        "--template minimal --theme compose --validate-only"
        "--config $TEST_TEMP_DIR/medium_config.json --validate-only"
        "--template corporate --output $TEST_OUTPUT_DIR --force --validate-only"
    )

    local total_time=0
    for validation in "${validations[@]}"; do
        local duration_ms
        duration_ms=$(time_command "$SCRIPT_DIR/build.sh $validation")
        total_time=$((total_time + duration_ms))
    done

    # All validations should complete quickly (under 2 seconds total)
    assert_performance_threshold "$total_time" 2000 "multiple parameter validations"

    echo "# Multiple validations total time: ${total_time}ms" >&3
}

@test "performance benchmark: error handling speed" {
    # Test various error scenarios for performance
    local error_scenarios=(
        "--template nonexistent --validate-only"
        "--config /nonexistent/config.json --validate-only"
        "--template corporate --output /invalid/path --validate-only"
    )

    local total_error_time=0
    for scenario in "${error_scenarios[@]}"; do
        local duration_ms
        duration_ms=$(time_command "$SCRIPT_DIR/build.sh $scenario 2>/dev/null || true")
        total_error_time=$((total_error_time + duration_ms))
    done

    # Error handling should be fast (under 1 second total)
    assert_performance_threshold "$total_error_time" 1000 "error scenario handling"

    echo "# Error scenarios total time: ${total_error_time}ms" >&3
}

@test "performance benchmark: component parsing efficiency" {
    # Create templates with varying numbers of components
    local template_no_components="$PROJECT_ROOT/templates/no_components"
    local template_many_components="$PROJECT_ROOT/templates/many_components"

    mkdir -p "$template_no_components" "$template_many_components"

    # Template with no components
    echo "# No Components Template" > "$template_no_components/README.md"

    # Template with many components
    echo "# Many Components Template" > "$template_many_components/README.md"
    cat > "$template_many_components/components.yml" << 'EOF'
components:
  - name: quiz-engine
    version: "1.0.0"
  - name: analytics
    version: "2.1.0"
  - name: search
    version: "1.5.0"
  - name: auth
    version: "3.0.0"
  - name: comments
    version: "1.2.0"
  - name: newsletter
    version: "2.0.0"
  - name: social-share
    version: "1.1.0"
  - name: seo-optimizer
    version: "1.0.0"
EOF

    # Benchmark both
    local no_components_time
    no_components_time=$(time_command "$SCRIPT_DIR/build.sh --template no_components --validate-only")

    local many_components_time
    many_components_time=$(time_command "$SCRIPT_DIR/build.sh --template many_components --validate-only")

    # Component parsing shouldn't add excessive overhead
    local overhead=$((many_components_time - no_components_time))
    assert_performance_threshold "$overhead" 1000 "component parsing overhead"

    echo "# No components: ${no_components_time}ms, Many components: ${many_components_time}ms, Overhead: ${overhead}ms" >&3
}

@test "performance regression: build time consistency" {
    # Run the same build multiple times to check for consistency
    local build_times=()
    local iterations=3

    for ((i=1; i<=iterations; i++)); do
        local duration_ms
        duration_ms=$(time_command "$SCRIPT_DIR/build.sh --template corporate --output $TEST_OUTPUT_DIR --force")
        build_times+=($duration_ms)

        # Clean up between iterations
        rm -rf "$TEST_OUTPUT_DIR"
    done

    # Calculate variance (simple check for consistency)
    local min_time=${build_times[0]}
    local max_time=${build_times[0]}

    for time in "${build_times[@]}"; do
        [ "$time" -lt "$min_time" ] && min_time=$time
        [ "$time" -gt "$max_time" ] && max_time=$time
    done

    local variance=$((max_time - min_time))

    # Variance should be less than 50% of minimum time (build times should be consistent)
    local max_variance=$((min_time / 2))
    [ "$variance" -lt "$max_variance" ]

    echo "# Build time consistency: min=${min_time}ms, max=${max_time}ms, variance=${variance}ms" >&3
}

@test "performance benchmark: startup overhead" {
    # Measure just the script startup time (using --help as minimal operation)
    local startup_time
    startup_time=$(time_command "$SCRIPT_DIR/build.sh --help >/dev/null")

    # Script startup should be very fast (under 50ms)
    assert_performance_threshold "$startup_time" 50 "script startup overhead"

    echo "# Script startup time: ${startup_time}ms" >&3
}