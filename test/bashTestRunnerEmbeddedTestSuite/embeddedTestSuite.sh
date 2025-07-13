#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Embedded test suite that tests the bashTestRunner by running other test suites

# Test that runs the basic test suite


# Test that runs the example test suite


# Test that verifies metrics from a custom test run
bashTestRunnerEmbeddedTestSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C
  
  local test_functions=(
    "testEmbeddedRunBasicTestSuite"
    "testEmbeddedRunExampleTestSuite"
    "testEmbeddedCustomTestRun"
  )
  
  local ignored_tests=(
    # None of these tests are ignored
  )
  
  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}