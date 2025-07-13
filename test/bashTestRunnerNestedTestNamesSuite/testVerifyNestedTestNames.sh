#!/usr/bin/env bash
testVerifyNestedTestNames() {
  echo "Verifying display of nested test names"
  
  # Define outer test functions as the sub-suite runners
  local outer_tests=(
    "runSubSuiteA"
    "runSubSuiteB"
  )
  
  local outer_ignored=()
  
  # Create a temporary file for capturing output
  local temp_output=$(mktemp)
  
  # Capture output and result from running the outer bashTestRunner
  bashTestRunner outer_tests outer_ignored > "$temp_output" 2>&1
  local result=$?
  
  # Read the captured output
  local output=$(cat "$temp_output")
  rm -f "$temp_output"
  
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