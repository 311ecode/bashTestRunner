#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Test suite to verify session directory path is correctly reported

# Main function to run the session directory path test suite
bashTestRunnerLogFilePathTestSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C

  local test_functions=(
    "testLogFilePathSimplePass"
    "testLogFilePathSimpleFail"
    "testLogFilePathNestedCall"
    "testVerifyTopLevelLogPath"
    "testVerifyNestedLogPath"
    "testVerifyDeeplyNestedLogPath"
    "testVerifyIgnoredLogFileNaming"
  )

  local ignored_tests=(
    "testLogFilePathSimpleFail"  # Ignore the failing test
  )

  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}
