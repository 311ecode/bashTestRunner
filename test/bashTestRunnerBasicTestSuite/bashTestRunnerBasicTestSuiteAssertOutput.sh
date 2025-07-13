#!/usr/bin/env bash
bashTestRunnerBasicTestSuiteAssertOutput() {
  # Create a temporary file for capturing output
  local temp_output=$(mktemp)
  
  # Run the test suite and capture output, ensuring all output is flushed
  bashTestRunnerBasicTestSuiteRunner > "$temp_output" 2>&1
  local status=$?
  
  # Ensure all output is written to the file
  sync
  sleep 0.1
  
  # Read the captured output
  local output=$(cat "$temp_output")
  rm -f "$temp_output"
  
  # Debug: Show what we captured
  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: Captured output length: ${#output}" >&2
    echo "DEBUG: First 200 chars: ${output:0:200}" >&2
  fi
  
  # Check if the output contains the expected summary
  # Note: Total tests = 2 because bashTestRunnerBasicTestSuiteFail is ignored
  if ! echo "$output" | grep -q "Total tests: 2"; then
    echo "ERROR: Output does not contain 'Total tests: 2'"
    echo "DEBUG: Full output was:" >&2
    echo "$output" >&2
    return 1
  fi
  
  if ! echo "$output" | grep -q "Passed: 2"; then
    echo "ERROR: Output does not contain 'Passed: 2'"
    return 1
  fi
  
  if ! echo "$output" | grep -q "Failed: 0"; then
    echo "ERROR: Output does not contain 'Failed: 0'"
    return 1
  fi
  
  if ! echo "$output" | grep -q "Ignored tests: 1 (Passed: 0, Failed: 1)"; then
    echo "ERROR: Output does not contain 'Ignored tests: 1 (Passed: 0, Failed: 1)'"
    return 1
  fi
  
  # Check if the output contains the detailed results
  if ! echo "$output" | grep -q "PASS: bashTestRunnerBasicTestSuitePass"; then
    echo "ERROR: Output does not contain 'PASS: bashTestRunnerBasicTestSuitePass'"
    return 1
  fi
  
  if ! echo "$output" | grep -q "IGNORED (FAIL): bashTestRunnerBasicTestSuiteFail"; then
    echo "ERROR: Output does not contain 'IGNORED (FAIL): bashTestRunnerBasicTestSuiteFail'"
    return 1
  fi
  
  if ! echo "$output" | grep -q "PASS: bashTestRunnerBasicTestSuiteStringComparison"; then
    echo "ERROR: Output does not contain 'PASS: bashTestRunnerBasicTestSuiteStringComparison'"
    return 1
  fi
  
  # Check the final status message
  if ! echo "$output" | grep -q "PASS: All 2 tests passed successfully"; then
    echo "ERROR: Output does not contain 'PASS: All 2 tests passed successfully'"
    return 1
  fi
  
  return 0
}