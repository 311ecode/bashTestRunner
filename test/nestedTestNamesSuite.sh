#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Test suite to verify that nested test names are displayed correctly in output

# Inner test functions for sub-suite A
nested_innerAPass() {
  echo "Inner A passing test"
  return 0
}

nested_innerAFail() {
  echo "Inner A failing test"
  return 1
}

# Runner function for sub-suite A
runSubSuiteA() {
  local test_functions=(
    "nested_innerAPass"
    "nested_innerAFail"
  )
  
  local ignored_tests=(
    "nested_innerAFail"
  )
  
  bashTestRunner test_functions ignored_tests
  return $?
}

# Inner test functions for sub-suite B
nested_innerBPass() {
  echo "Inner B passing test"
  return 0
}

# Runner function for sub-suite B
runSubSuiteB() {
  local test_functions=(
    "nested_innerBPass"
  )
  
  local ignored_tests=()
  
  bashTestRunner test_functions ignored_tests
  return $?
}

# Verification test that runs two sub-suites via another bashTestRunner and checks if test names are correctly displayed
testVerifyNestedTestNames() {
  echo "Verifying display of nested test names"
  
  # Define outer test functions as the sub-suite runners
  local outer_tests=(
    "runSubSuiteA"
    "runSubSuiteB"
  )
  
  local outer_ignored=()
  
  # Capture output and result from running the outer bashTestRunner
  local output
  output=$(bashTestRunner outer_tests outer_ignored 2>&1)
  local result=$?
  
  local errors=""
  
  # Check for expected "Running test:" lines from outer level
  if ! echo "$output" | grep -q "Running test: runSubSuiteA"; then
    errors+="ERROR: Output missing 'Running test: runSubSuiteA'\n"
  fi
  
  if ! echo "$output" | grep -q "Running test: runSubSuiteB"; then
    errors+="ERROR: Output missing 'Running test: runSubSuiteB'\n"
  fi
  
  # Check for expected "Running test:" lines from inner levels
  if ! echo "$output" | grep -q "Running test: nested_innerAPass"; then
    errors+="ERROR: Output missing 'Running test: nested_innerAPass'\n"
  fi
  
  if ! echo "$output" | grep -q "Running test: nested_innerAFail"; then
    errors+="ERROR: Output missing 'Running test: nested_innerAFail'\n"
  fi
  
  if ! echo "$output" | grep -q "Running test: nested_innerBPass"; then
    errors+="ERROR: Output missing 'Running test: nested_innerBPass'\n"
  fi
  
  # Check for expected detailed results lines from inner levels
  if ! echo "$output" | grep -q "PASS: nested_innerAPass"; then
    errors+="ERROR: Output missing 'PASS: nested_innerAPass'\n"
  fi
  
  if ! echo "$output" | grep -q "IGNORED (FAIL): nested_innerAFail"; then
    errors+="ERROR: Output missing 'IGNORED (FAIL): nested_innerAFail'\n"
  fi
  
  if ! echo "$output" | grep -q "PASS: nested_innerBPass"; then
    errors+="ERROR: Output missing 'PASS: nested_innerBPass'\n"
  fi
  
  # Check for expected detailed results lines from outer level
  if ! echo "$output" | grep -q "PASS: runSubSuiteA"; then
    errors+="ERROR: Output missing 'PASS: runSubSuiteA'\n"
  fi
  
  if ! echo "$output" | grep -q "PASS: runSubSuiteB"; then
    errors+="ERROR: Output missing 'PASS: runSubSuiteB'\n"
  fi
  
  if [ -n "$errors" ]; then
    echo -e "$errors"
    echo "bashTestRunner returned: $result"
    echo "Full captured output:"
    echo "$output"
    return 1
  else
    echo "Nested test names displayed correctly"
    return 0
  fi
}

# Main function to run the nested test names suite
nestedTestNamesSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C
  
  local test_functions=(
    "testVerifyNestedTestNames"
  )
  
  local ignored_tests=()
  
  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}
