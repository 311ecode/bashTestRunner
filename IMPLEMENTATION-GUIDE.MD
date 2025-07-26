# Implementation Guide: bashTestRunner Test Suites

## Overview

This guide explains how to create comprehensive test suites using the bashTestRunner framework, based on the ModelSelectionStrategy test implementation. You can create isolated, self-contained test files without embedding the entire bashTestRunner source code.

## Core Concepts

### What This Framework Provides

**Automated Test Execution**: The bashTestRunner automatically discovers and runs test functions, eliminating manual test orchestration.

**Environment Isolation**: Each test can safely modify environment variables and restore them afterward, preventing test interference.

**Flexible Test Organization**: Tests can be selectively ignored or grouped by functionality.

**On-Demand Execution**: Tests run when you execute the script.

## File Structure Template - Nested Test Runner Approach

```bash
#!/usr/bin/env bash
# Copyright and licensing information

# @file yourTestFile.sh
# @brief Test suite description
# @description Comprehensive tests using bashTestRunner framework

# Main test suite function with nested structure
testYourFeature() {
  export LC_NUMERIC=C  # Required: Ensures consistent numeric formatting across tests
  
  # Define individual test functions INSIDE the main test runner
  testBasicFunctionality() {
    echo "Testing basic functionality"
    # Test implementation here
    return 0
  }
  
  testErrorHandling() {
    echo "Testing error conditions"
    # Test implementation here
    return 0
  }
  
  testEnvironmentVariables() {
    echo "Testing environment variable handling"
    # Test implementation here
    return 0
  }
  
  testEdgeCases() {
    echo "Testing edge cases"
    # Test implementation here
    return 0
  }
  
  # Test function registry
  local test_functions=(
    "testBasicFunctionality"
    "testErrorHandling"
    "testEnvironmentVariables"
    "testEdgeCases"
  )
  
  local ignored_tests=()  # Add test names to skip
  
  bashTestRunner test_functions ignored_tests
  return $?
}

# Execute test suite if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  testYourFeature
fi
```

This nested structure provides **superior error reporting** with clear hierarchical paths like:
`testYourFeature -> testBasicFunctionality -> specific assertion`

## Essential Requirements

### LC_NUMERIC Setting

**Required**: Tests must set `LC_NUMERIC=C` to ensure consistent numeric formatting and prevent locale-specific number formatting issues.

**Two approaches:**

1. **Export method** (recommended for multiple operations):
   ```bash
   export LC_NUMERIC=C
   bashTestRunner test_functions ignored_tests
   ```

2. **Command-specific method** (for single command):
   ```bash
   LC_NUMERIC=C bashTestRunner test_functions ignored_tests
   ```

Both ensure that numeric operations and comparisons work consistently regardless of system locale.

### Step 1: Define Your Test Suite Structure

Create a main test function that declares all individual test functions:

```bash
testYourFeature() {
  local test_functions=(
    "testFirstScenario"
    "testSecondScenario" 
    "testErrorCondition"
  )
  
  local ignored_tests=()
  bashTestRunner test_functions ignored_tests
  return $?
}
```

### Step 2: Implement Individual Test Functions (Nested Structure)

Each test function should be defined **inside** the main test runner function for better error tracing:

```bash
testYourFeature() {
  # Define test functions inside main runner
  testFirstScenario() {
    echo "Testing basic functionality"
    
    # Save current environment state
    local saved_var="${IMPORTANT_VAR:-}"
    
    # Configure test environment
    export IMPORTANT_VAR="test_value"
    
    # Execute the function under test
    local result
    result=$(yourFunctionToTest "test input")
    
    # Restore environment
    if [[ -n "$saved_var" ]]; then
      export IMPORTANT_VAR="$saved_var"
    else
      unset IMPORTANT_VAR
    fi
    
    # Assert results
    if [[ "$result" == "expected_output" ]]; then
      echo "SUCCESS: Test passed"
      return 0
    else
      echo "ERROR: Expected 'expected_output', got '$result'"
      return 1
    fi
  }
  
  testSecondScenario() {
    echo "Testing another scenario"
    # Implementation here
    return 0
  }
  
  # Test registry at the end
  local test_functions=(
    "testFirstScenario"
    "testSecondScenario"
  )
  
  local ignored_tests=()
  
  # Two approaches for LC_NUMERIC:
  # Option 1: Already exported above
  bashTestRunner test_functions ignored_tests
  
  # Option 2: Set only for this command
  # LC_NUMERIC=C bashTestRunner test_functions ignored_tests
  
  return $?
}
```

**Benefits of Nested Structure:**
- Clear error paths: `testYourFeature -> testFirstScenario -> assertion failure`
- Better encapsulation and organization
- Superior debugging experience with hierarchical error reporting

### Step 3: Environment Management Best Practices

**Save Before Modify**: Always save environment variables before changing them:

```bash
local saved_strategies="${ModelSelectionStrategies:-}"
local saved_api_key="${API_KEY:-}"
```

**Clean Restoration**: Restore variables using proper unset logic:

```bash
if [[ -n "$saved_strategies" ]]; then
  export ModelSelectionStrategies="$saved_strategies"
else
  unset ModelSelectionStrategies
fi
```

**Temporary Files**: Use proper cleanup for temporary resources:

```bash
local temp_output=$(mktemp)
# ... use temp file ...
rm -f "$temp_output"
```

### Step 4: Testing Different Scenarios

**Success Path Testing**:
```bash
testUserPreferenceStrategy() {
  # Set up conditions for successful execution
  export USER_PREFERRED_MODEL="preferred:model"
  local result=$(selectModelWithStrategy "test prompt")
  
  if [[ "$result" == "preferred:model" ]]; then
    echo "SUCCESS: User preference honored"
    return 0
  fi
}
```

**Error Condition Testing**:
```bash
testMissingDependency() {
  # Remove required dependency
  unset REQUIRED_API_KEY
  
  # Capture error output
  local temp_output=$(mktemp)
  yourFunction "test" 2>"$temp_output" >/dev/null
  
  if grep -q "Expected error message" "$temp_output"; then
    echo "SUCCESS: Error handling works"
    rm -f "$temp_output"
    return 0
  fi
}
```

**Fallback Chain Testing**:
```bash
testStrategyFallback() {
  # Configure primary strategy to fail, secondary to succeed
  export STRATEGIES="primary,secondary,tertiary"
  unset PRIMARY_CONFIG  # Force fallback
  export SECONDARY_CONFIG="working"
  
  local result=$(executeWithFallback "input")
  # Verify secondary strategy was used
}
```

## Advanced Patterns

### Testing Strategy Chains

When testing systems with multiple fallback strategies:

```bash
testComplexFallback() {
  # Set up environment where first two strategies fail
  export STRATEGY_CHAIN="strategy1,strategy2,strategy3"
  unset STRATEGY1_REQUIREMENT
  unset STRATEGY2_REQUIREMENT  
  export STRATEGY3_REQUIREMENT="available"
  
  local result=$(executeStrategies "context")
  
  # Verify strategy3 was ultimately selected
  if [[ "$result" == "strategy3:output" ]]; then
    echo "SUCCESS: Fallback chain working"
    return 0
  fi
}
```

### Testing Availability Checks

For systems that check resource availability:

```bash
testAvailabilityLogic() {
  # Test unavailable condition
  unset RESOURCE_KEY
  if isResourceAvailable "resource:name"; then
    echo "ERROR: Should not be available without key"
    return 1
  fi
  
  # Test available condition
  export RESOURCE_KEY="test-key"
  if ! isResourceAvailable "resource:name"; then
    echo "ERROR: Should be available with key"
    return 1
  fi
  
  echo "SUCCESS: Availability checks working"
  return 0
}
```

## Framework Integration - Zero Configuration

The bashTestRunner framework is **automatically available** in your environment. You don't need to:

- Source any files
- Include function definitions
- Set up PATH variables
- Embed any runner code

Simply reference the `bashTestRunner` function name and the system automatically provides it. This makes test files completely clean and dependency-free.

## Test Function Requirements

**All tests must be functions** that follow this contract:
- **Return 0** for success/pass
- **Return 1** for failure
- Provide clear output messages indicating test results

```bash
testExample() {
  echo "Testing something specific"
  
  if [[ condition_met ]]; then
    echo "SUCCESS: Test description"
    return 0  # Pass
  else
    echo "ERROR: Expected X, got Y"
    return 1  # Fail
  fi
}
```

## Best Practices Summary

**Isolation**: Each test should be completely independent and not affect others.

**Descriptive Names**: Use clear, descriptive function names that explain what's being tested.

**Environment Safety**: Always save and restore environment variables.

**Clear Output**: Provide clear success/failure messages with expected vs actual values.

**Error Handling**: Test both success and failure conditions.

**Documentation**: Include brief descriptions of what each test validates.

**Modular Design**: Group related tests together, but keep individual tests focused.

This approach gives you powerful, maintainable test suites without the complexity of perpetual file monitoring or heavy framework dependencies.
