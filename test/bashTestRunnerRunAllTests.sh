#!/bin/bash
bashTestRunnerRunAllTests() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C
  
  # Define test functions (our test suites)
  local test_suites=(
    "basicTestSuite"
    "embeddedTestSuite"
    "failureStatusTestSuite"
    "bashTestRunner_ignoredFailureTestSuite"
  )
  
  local ignored_suites=(
    # None of the test suites are ignored by default
  )
  
  # Run bashTestRunner to execute all test suites
  bashTestRunner test_suites ignored_suites
  return $?
}
