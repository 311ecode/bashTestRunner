#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Basic test suite using bashTestRunner

# A simple test that succeeds
testBasicTestSuitePass() {
  echo "Running a simple passing test"
  sleep 1  # Sleep for 1 second
  return 0
}

# A simple test that fails
testBasicTestSuiteFail() {
  echo "Running a simple failing test"
  return 1
}

# A test with some actual logic
testBasicTestSuiteStringComparison() {
  local str1="hello"
  local str2="hello"
  
  if [[ "$str1" == "$str2" ]]; then
    sleep 1.5  # Sleep for 1.5 seconds
    return 0
  else
    return 1
  fi
}


# Test that asserts the output of the test runner
testBasicTestSuiteAssertOutput() {
  # Run the test suite and capture its output
  local output=$(basicTestSuiteRunner 2>&1)
  
  # Check if the output contains the expected summary
  if ! echo "$output" | grep -q "Total tests: 3"; then
    echo "ERROR: Output does not contain 'Total tests: 3'"
    return 1
  fi
  
  if ! echo "$output" | grep -q "Passed: 2"; then
    echo "ERROR: Output does not contain 'Passed: 2'"
    return 1
  fi
  
  if ! echo "$output" | grep -q "Failed: 1"; then
    echo "ERROR: Output does not contain 'Failed: 1'"
    return 1
  fi
  
  if ! echo "$output" | grep -q "Ignored tests: 1 (Passed: 0, Failed: 1)"; then
    echo "ERROR: Output does not contain 'Ignored tests: 1 (Passed: 0, Failed: 1)'"
    return 1
  fi
  
  # Check if the output contains the detailed results
  if ! echo "$output" | grep -q "PASS: testBasicTestSuitePass"; then
    echo "ERROR: Output does not contain 'PASS: testBasicTestSuitePass'"
    return 1
  fi
  
  if ! echo "$output" | grep -q "IGNORED (FAIL): testBasicTestSuiteFail"; then
    echo "ERROR: Output does not contain 'IGNORED (FAIL): testBasicTestSuiteFail'"
    return 1
  fi
  
  if ! echo "$output" | grep -q "PASS: testBasicTestSuiteStringComparison"; then
    echo "ERROR: Output does not contain 'PASS: testBasicTestSuiteStringComparison'"
    return 1
  fi
  

  
  return 0
}

# Helper function to run basic tests for assertion testing
basicTestSuiteRunner() {
  export LC_NUMERIC=C
  
  local test_functions=(
    "testBasicTestSuitePass"
    "testBasicTestSuiteFail"
    "testBasicTestSuiteStringComparison"
  )
  
  local ignored_tests=(
    "testBasicTestSuiteFail"  # We're ignoring the failing test for this example
  )
  
  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}

# Run the test suite
basicTestSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C
  
  local test_functions=(
    "testBasicTestSuitePass"
    "testBasicTestSuiteFail"
    "testBasicTestSuiteStringComparison"
    "testBasicTestSuiteAssertOutput"  # Added assertion test
  )
  
  local ignored_tests=(
    "testBasicTestSuiteFail"  # We're ignoring the failing test for this example
  )
  
  # Run the test suite
  bashTestRunner test_functions ignored_tests
  echo $? xxxxxxxxxxxxxxxxxxxXXxxxXXXxxXXXxxXXXXXXXXxxXXX
  return $?
}

# Execute the test suite if this script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  basicTestSuite
fi
