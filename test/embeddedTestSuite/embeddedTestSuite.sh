#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Embedded test suite that tests the bashTestRunner by running other test suites

# Test that runs the basic test suite
testEmbeddedRunBasicTestSuite() {
  echo "Running the basic test suite as an embedded test"
  
  # Run the test suite and check its return value
  basicTestSuite
  local result=$?
  
  if [[ $result -eq 0 ]]; then
    echo "Basic test suite passed successfully"
    return 0
  else
    echo "Basic test suite failed with exit code $result"
    return 1
  fi
}

# Test that runs the example test suite
testEmbeddedRunExampleTestSuite() {
  echo "Running the example test suite as an embedded test"
  
  # Run the test suite and check its return value
  exampleTestSuite
  local result=$?
  
  # We expect the example test suite to pass since its failing test is ignored
  if [[ $result -eq 0 ]]; then
    echo "Example test suite passed successfully as expected"
    return 0
  else
    echo "Example test suite failed with exit code $result, but should have passed"
    return 1
  fi
}

# Test that verifies metrics from a custom test run
testEmbeddedCustomTestRun() {
  echo "Running a custom test with controlled test functions"
  
  # Define custom test functions
  customTestPass() { return 0; }
  customTestFail() { return 1; }
  
  # Create arrays for the test runner
  local test_functions=(
    "customTestPass"
    "customTestFail"
  )
  
  local ignored_tests=()
  
  # Create a temporary file for capturing output
  local temp_output=$(mktemp)
  
  # Run the test suite and capture output and exit status
  bashTestRunner test_functions ignored_tests > "$temp_output" 2>&1
  local result=$?
  
  # Read the captured output
  local output=$(cat "$temp_output")
  rm -f "$temp_output"
  
  # Verify the test runner returned failure (since one test failed)
  if [[ $result -ne 1 ]]; then
    echo "ERROR: Test runner should have returned 1, but returned $result"
    return 1
  fi
  
  # Verify the output contains the expected summary
  if ! echo "$output" | grep -q "Total tests: 2"; then
    echo "ERROR: Output does not contain 'Total tests: 2'"
    return 1
  fi
  
  if ! echo "$output" | grep -q "Passed: 1"; then
    echo "ERROR: Output does not contain 'Passed: 1'"
    return 1
  fi
  
  if ! echo "$output" | grep -q "Failed: 1"; then
    echo "ERROR: Output does not contain 'Failed: 1'"
    return 1
  fi
  
  echo "Custom test verification passed successfully"
  return 0
}

# Main function to run the embedded test suite
embeddedTestSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C
  
  local test_functions=(
    "testEmbeddedRunBasicTestSuite"
    "testEmbeddedRunExampleTestSuite"
    "testEmbeddedCustomTestRun"
  )
  
  local ignored_tests=(
    # None of these tests are ignored
  )
  
  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}