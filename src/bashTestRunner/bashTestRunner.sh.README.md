# bashTestRunner - Bash Test Framework

## Overview
bashTestRunner is a comprehensive test framework for Bash scripts that provides test organization, execution, reporting, and debugging capabilities. It supports regular and ignored tests, deterministic test shuffling, seed hunting for order-dependent bugs, and hierarchical failure reporting.

## Quick Start

### Basic Usage
```bash
# Define test functions and arrays
testExample1() { return 0; }
testExample2() { return 1; }

myTests=("testExample1" "testExample2")
ignored=("testExample2")

# Run tests
bashTestRunner myTests ignored
```

### Advanced Features
```bash
# Hunt for order-dependent failures
bashTestRunner myTests ignored --find-failing-seeds

# Reproduce a specific failure
bashTestRunner myTests ignored --reproduce "abc123"

# Exclude additional tests
bashTestRunner myTests ignored --exclude "testExample3 testExample4"

# Run with deterministic shuffling
BASH_TEST_RUNNER_SEED=42 bashTestRunner myTests ignored
```

## Command Line Options

### Required Parameters
- `<test_functions_array>`: Name of an array variable containing all test functions to run
- `<ignored_tests_array>`: Name of an array variable containing tests to ignore

### Optional Parameters
- `-x, --exclude <tests>`: Space-separated list of additional tests to ignore (quoted if multiple)
- `-ff, --find-failing-seeds`: Hunt for seeds that cause test failures
- `-ffl, --find-failing-seeds-limit N`: Limit seed hunting to N attempts (default: 100)
- `-r, --reproduce <seed>`: Reproduce a bug using a specific seed
- `-h, --help`: Show help message

## Environment Variables

- `BASH_TEST_RUNNER_SEED`: Set specific seed for deterministic test shuffling
- `DEBUG`: Enable debug output for troubleshooting
- `LC_NUMERIC=C`: Set for consistent decimal handling (automatically set by framework)

## Detailed Usage Examples

### Normal Test Execution
```bash
# Simple test run
testPass() { echo "Passing"; return 0; }
testFail() { echo "Failing"; return 1; }

tests=("testPass" "testFail")
ignored=("testFail")

bashTestRunner tests ignored
```

### Test Shuffling
```bash
# Run with specific seed (deterministic order)
BASH_TEST_RUNNER_SEED=123 bashTestRunner tests ignored

# Run with string seed
BASH_TEST_RUNNER_SEED="my-test-run" bashTestRunner tests ignored

# Each run with same seed produces identical order
BASH_TEST_RUNNER_SEED=123 bashTestRunner tests ignored  # Same order
BASH_TEST_RUNNER_SEED=123 bashTestRunner tests ignored  # Same order
```

### Finding Order-Dependent Bugs
```bash
# Hunt for failing seeds (up to 100 attempts)
bashTestRunner tests ignored --find-failing-seeds

# Hunt with custom limit
bashTestRunner tests ignored --find-failing-seeds --find-failing-seeds-limit 50

# Results saved to ./failing-seeds and ./test-executions.log
```

### Bug Reproduction
```bash
# Reproduce a specific failure
bashTestRunner tests ignored --reproduce "abc123def456"

# Output saved to ./bug-reproduction-abc123def456.log
```

### Excluding Tests
```bash
# Exclude specific tests from current run
bashTestRunner tests ignored --exclude "flakyTest intermittentTest"

# Combine with pre-ignored tests
ignored=("alwaysFails")
bashTestRunner tests ignored --exclude "sometimesFails"
```

## Key Features

### Test Organization
- **Test Functions**: Regular Bash functions (typically prefixed with `test`)
- **Test Suites**: Collections of test functions organized in arrays
- **Ignored Tests**: Tests that run but don't affect overall status
- **Nested Suites**: Support for test suites that call other test suites

### Deterministic Test Shuffling
- **Seed-Based**: Uses Fisher-Yates shuffle with deterministic RNG
- **Flexible Seeds**: Supports numeric, string, and hash-based seeds
- **Reproducible**: Same seed produces identical test order
- **Order Discovery**: Helps identify order-dependent test failures

### Advanced Debugging
- **Seed Hunting**: Automatically discovers seeds that cause test failures
- **Bug Reproduction**: Reproduces specific failures with detailed logging
- **Hierarchical Paths**: Shows full test call paths for nested failures
- **Session Management**: Creates isolated test sessions with detailed logs

### Comprehensive Reporting
- **Real-time Output**: Live test execution display via tail
- **Detailed Logs**: Individual test logs with execution timing
- **Session Directories**: Organized log storage for analysis
- **Summary Reports**: Clear pass/fail status with recommendations

## Test Structure Guidelines

### Basic Test Function
```bash
testExample() {
    # Test setup
    local expected="hello"
    local actual=$(some_command)
    
    # Assertion
    if [[ "$actual" == "$expected" ]]; then
        return 0  # Success
    else
        echo "Expected: $expected, Got: $actual"
        return 1  # Failure
    fi
}
```

### Test Suite Organization
```bash
# Define test arrays
test_functions=(
    "testFeatureA"
    "testFeatureB" 
    "testFeatureC"
)

ignored_tests=(
    "testFeatureB"  # Temporarily disabled
)

# Run the suite
bashTestRunner test_functions ignored_tests
```

### Nested Test Suites
```bash
parentSuite() {
    local child_tests=("childTest1" "childTest2")
    local child_ignored=()
    bashTestRunner child_tests child_ignored
    return $?
}
```

## Output and Logging

### Real-time Display
- Top-level runs show live test execution via `tail -f`
- Individual test output captured in real-time
- Progress indicators and timing information

### Log Files
- **Main Log**: Complete test session output in `/tmp/bashTestRunnerSessions/.../main.log`
- **Individual Logs**: Per-test logs with hierarchical naming
- **Ignored Tests**: Log files marked with `-IGNORED` suffix

### Session Management
```bash
# Session directory reported at end of top-level runs
Session directory: /tmp/bashTestRunnerSessions/20250101120000-abc123def
Main log file: /tmp/bashTestRunnerSessions/20250101120000-abc123def/main.log

# View results later
cat "/tmp/bashTestRunnerSessions/20250101120000-abc123def/main.log"
```

## Advanced Usage Patterns

### Order-Dependent Test Detection
```bash
# Tests that depend on execution order
statefulTestA() {
    touch "/tmp/test-state"
    return 0
}

statefulTestB() {
    if [[ ! -f "/tmp/test-state" ]]; then
        return 1  # Fails if run before statefulTestA
    fi
    return 0
}

# Hunt for problematic orders
bashTestRunner tests ignored --find-failing-seeds
```

### Complex Test Hierarchies
```bash
# Multi-level test nesting
level1Test() {
    level2Test() {
        level3Test() {
            return 1  # Deep failure
        }
        local tests=("level3Test")
        bashTestRunner tests ignored
    }
    local tests=("level2Test") 
    bashTestRunner tests ignored
}

# Shows full path: level1Test->level2Test->level3Test
```

### Integration with CI/CD
```bash
#!/bin/bash
# Example CI script

# Run all test suites
if bashTestRunnerRunAllTests; then
    echo "All tests passed"
    exit 0
else
    echo "Tests failed - check session logs"
    exit 1
fi
```

## Best Practices

### Test Design
1. **Keep tests focused**: One assertion per test when possible
2. **Use descriptive names**: Clear test function names
3. **Handle setup/teardown**: Clean up test state
4. **Avoid external dependencies**: Mock or stub external systems
5. **Use ignored tests wisely**: For temporarily disabled tests

### Execution Strategy
1. **Regular shuffling**: Run with different seeds to find order issues
2. **Seed hunting**: Use automated discovery for flaky tests
3. **Reproduction**: Save failing seeds for debugging
4. **Session analysis**: Use log files for post-mortem debugging

### Performance Considerations
1. **Minimal sleep**: Avoid unnecessary delays in tests
2. **Efficient assertions**: Use built-in Bash comparisons when possible
3. **Resource cleanup**: Remove temporary files and processes
4. **Session cleanup**: Old sessions automatically cleaned by system

## Troubleshooting

### Common Issues

**Tests not found**: Ensure test functions are defined and exported if needed

**Unexpected order**: Check `BASH_TEST_RUNNER_SEED` environment variable

**Missing output**: Verify session directory exists and check main.log

**Nested test issues**: Ensure proper environment variable handling in nested calls

### Debug Mode
```bash
# Enable debug output
DEBUG=1 bashTestRunner tests ignored

# Shows detailed execution information and variable states
```

### Error Patterns
- **Command not found**: Test function doesn't exist
- **Permission denied**: Log directory access issues  
- **Variable conflicts**: Test function names shadowing other functions
- **Environment pollution**: Nested tests affecting each other

## Included Test Suites

The framework includes comprehensive test suites that verify its own functionality:

- **Basic Test Suite**: Simple pass/fail scenarios
- **Embedded Test Suite**: Nested test execution
- **Failure Status Suite**: Exit code verification
- **Ignored Failure Suite**: Ignored test handling
- **Shuffle Test Suite**: Deterministic shuffling
- **Seed Hunting Suite**: Failure discovery
- **Hierarchical Failure Suite**: Nested path reporting
- **Exclude Option Suite**: Command line exclusion
- **And many more...**

Run all test suites:
```bash
bashTestRunnerRunAllTests
```

## Dependencies

- **Bash 4.0+**: For associative arrays and advanced features
- **Core Utilities**: date, bc, tail, sha256sum, etc.
- **Temporary Storage**: /tmp directory for session logs

## License

Copyright © 2025 Imre Toth - Proprietary Software. See LICENSE file for terms.

## Support

For issues and feature requests, refer to the test suites for usage examples and verify against the comprehensive test coverage provided.
