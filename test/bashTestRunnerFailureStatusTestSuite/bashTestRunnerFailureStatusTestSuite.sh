#!/usr/bin/env bash
bashTestRunnerFailureStatusTestSuite() {
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
