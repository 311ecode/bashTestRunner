#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Test suite to verify that nested test names are displayed correctly in output

# Main function to run the nested test names suite
bashTestRunnerNestedTestNamesSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C

  local test_functions=(
    "testVerifyNestedTestNames"
  )

  local ignored_tests=()

  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}
