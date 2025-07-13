#!/usr/bin/env bash
basicTestSuiteRunner() {
  export LC_NUMERIC=C
  
  local test_functions=(
    "testBasicTestSuitePass"
    "testBasicTestSuiteFail"
    "testBasicTestSuiteStringComparison"
  )
  
  local ignored_tests=(
    "testBasicTestSuiteFail"  # We're ignoring the failing test for this example
  )
  
  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}