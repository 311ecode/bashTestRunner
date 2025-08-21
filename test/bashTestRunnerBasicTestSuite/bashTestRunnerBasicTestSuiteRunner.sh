#!/usr/bin/env bash
bashTestRunnerBasicTestSuiteRunner() {
  export LC_NUMERIC=C

  local test_functions=(
    "bashTestRunnerBasicTestSuitePass"
    "bashTestRunnerBasicTestSuiteFail"
    "bashTestRunnerBasicTestSuiteStringComparison"
  )

  local ignored_tests=(
    "bashTestRunnerBasicTestSuiteFail"  # We're ignoring the failing test for this example
  )

  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}
