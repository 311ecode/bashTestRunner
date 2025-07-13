#!/usr/bin/env bash
testEmbeddedCustomTestRun() {
  echo "Running a custom test with controlled test functions"
  
  # Define custom test functions
  testEmbeddedCustomTestRun_customTestPass() { return 0; }
  testEmbeddedCustomTestRun_customTestFail() { return 1; }
  
  # Create arrays for the test runner
  local test_functions=(
    "testEmbeddedCustomTestRun_customTestPass"
    "testEmbeddedCustomTestRun_customTestFail"
  )
  
  local ignored_tests=()
  
  # Create a temporary file for capturing output
  local temp_output=$(mktemp)
  
  # Run the test suite and capture output and exit status
  bashTestRunner test_functions ignored_tests > "$temp_output" 2>&1
  local result=$?
  
  # Read the captured output
  local output=$(cat "$temp_output")
  rm -f "$temp_output"
  
  # Verify the test runner returned failure (since one test failed)
  if [[ $result -ne 1 ]]; then
    echo "ERROR: Test runner should have returned 1, but returned $result"
    return 1
  fi
  
  # Verify the output contains the expected summary
  if ! echo "$output" | grep -q "Total tests: 2"; then
    echo "ERROR: Output does not contain 'Total tests: 2'"
    return 1
  fi
  
  if ! echo "$output" | grep -q "Passed: 1"; then
    echo "ERROR: Output does not contain 'Passed: 1'"
    return 1
  fi
  
  if ! echo "$output" | grep -q "Failed: 1"; then
    echo "ERROR: Output does not contain 'Failed: 1'"
    return 1
  fi
  
  echo "Custom test verification passed successfully"
  return 0
}