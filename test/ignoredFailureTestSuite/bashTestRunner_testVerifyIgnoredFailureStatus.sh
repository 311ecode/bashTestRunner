#!/usr/bin/env bash
bashTestRunner_testVerifyIgnoredFailureStatus() {
  echo "Verifying that ignored failing tests don't cause overall failure"
  
  # Create test functions for this verification
  local test_functions=(
    "bashTestRunner_testIgnoredFailureSuitePass"
    "bashTestRunner_testIgnoredFailureSuiteFail"
  )
  
  # The failing test is ignored
  local ignored_tests=(
    "bashTestRunner_testIgnoredFailureSuiteFail"
  )
  
  # Create a temporary file for capturing output
  local temp_output=$(mktemp)
  
  # Run bash test runner and capture output and exit status
  bashTestRunner test_functions ignored_tests > "$temp_output" 2>&1
  local return_code=$?
  
  # Read the captured output
  local output=$(cat "$temp_output")
  
  echo "=== Test Runner Output ==="
  echo "$output"
  echo "=== End Output ==="
  
  # Display the captured return code
  echo "bashTestRunner returned: $return_code"
  
  # Clean up temp file
  rm -f "$temp_output"
  
  # Verify the output contains expected information
  if ! echo "$output" | grep -q "IGNORED (FAIL): bashTestRunner_testIgnoredFailureSuiteFail"; then
    echo "ERROR: Output doesn't show the ignored failing test"
    return 1
  fi
  
  # Match the exact output format including the newline before "FINAL STATUS:"
  if ! echo "$output" | grep -q $'FINAL STATUS:\nPASS: All'; then
    echo "ERROR: Output doesn't show final PASS status in correct format"
    return 1
  fi
  
  # Verify the runner returned success (0) despite having an ignored failing test
  if [[ "$return_code" -ne 0 ]]; then
    echo "ERROR: Test runner returned non-zero ($return_code) despite failing test being ignored"
    return 1
  else
    echo "SUCCESS: Test runner correctly returned 0 (success) status"
    return 0
  fi
}