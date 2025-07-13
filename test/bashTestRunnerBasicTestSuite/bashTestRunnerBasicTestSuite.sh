#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Basic test suite using bashTestRunner

# Run the test suite
bashTestRunnerBasicTestSuite() {
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
  return $?
}

# Execute the test suite if this script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  basicTestSuite
fi