#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Test suite to verify the --exclude command line option in bashTestRunner

# Main function to run the exclude option test suite
bashTestRunnerExcludeOptionTestSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C
  
  local test_functions=(
    "testVerifyExcludeOption"
  )
  
  local ignored_tests=()
  
  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}