#!/bin/bash
# Main script to run all test suites

# Run all test suites using bashTestRunner
runAllTests() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C
  
  # Define test functions (our test suites)
  local test_suites=(
    "basicTestSuite"
    "embeddedTestSuite"
  )
  
  local ignored_suites=(
    # None of the test suites are ignored by default
  )
  
  # Run bashTestRunner to execute all test suites
  bashTestRunner test_suites ignored_suites
  return $?
}
