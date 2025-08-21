#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Test suite to verify behavior when a listed test function is missing (not defined)

# Main function to run the missing test suite
bashTestRunnerMissingTestSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C

  local test_functions=(
    "bashTestRunnerTestVerifyMissingTestStatus"
  )

  local ignored_tests=()

  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}
