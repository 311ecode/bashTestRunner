#!/usr/bin/env bash
bashTestRunner_ignoredFailureTestSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C

  local test_functions=(
    "bashTestRunner_testVerifyIgnoredFailureStatus"
  )

  local ignored_tests=(
    # Nothing is ignored in the main suite
  )

  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}
