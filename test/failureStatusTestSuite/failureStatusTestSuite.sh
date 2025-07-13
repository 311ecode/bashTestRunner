#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Test suite to verify that the test runner returns non-zero status on failure

# A simple test that will pass


# A test that will deliberately fail


# Test that verifies the test runner returns the correct exit code


# Main function to run the failure status test suite
failureStatusTestSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C
  
  local test_functions=(
    "testVerifyReturnStatus"
  )
  
  local ignored_tests=(
    # Nothing is ignored
  )
  
  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}