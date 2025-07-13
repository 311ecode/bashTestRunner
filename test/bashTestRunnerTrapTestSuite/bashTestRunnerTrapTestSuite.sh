#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Test suite for bashTestRunner where test functions use the trap function

# Run the test suite
bashTestRunnerTrapTestSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C
  
  local test_functions=(
    "bashTestRunnerTrapTestSuiteTrapPass"
    "bashTestRunnerTrapTestSuiteTrapFail"
  )
  
  local ignored_tests=(
    "bashTestRunnerTrapTestSuiteTrapFail"  # We're ignoring the failing test for this example
  )
  
  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}

# Execute the test suite if this script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  bashTestRunnerTrapTestSuite
fi