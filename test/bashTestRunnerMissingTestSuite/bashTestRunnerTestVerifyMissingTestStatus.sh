#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
bashTestRunnerTestVerifyMissingTestStatus() {
  echo "Verifying that attempting to execute a missing test function causes overall failure"
  
  # Define test array with a non-existent function
  local test_functions=(
    "non_existent_test_function_that_does_not_exist"
  )
  
  # No ignored tests
  local ignored_tests=()
  
  # Create a temporary file for capturing output
  local temp_output=$(mktemp)
  
  # Run bashTestRunner and capture output and exit status
  bashTestRunner test_functions ignored_tests > "$temp_output" 2>&1
  local return_code=$?
  
  # Read the captured output
  local output=$(cat "$temp_output")
  rm -f "$temp_output"
  
  # Display the captured return code
  echo "bashTestRunner returned: $return_code"
  
  # Verify the runner returned non-zero due to the missing function (Bash will treat it as command not found, exit 127, counted as failure)
  if [[ "$return_code" -ne 1 ]]; then
    echo "ERROR: Test runner should have returned 1 (failure) for missing test, but returned $return_code"
    echo "Captured output:"
    echo "$output"
    return 1
  fi
  
  # Optionally verify error message in output (Bash-specific "command not found")
  if ! echo "$output" | grep -q "command not found"; then
    echo "ERROR: Output does not indicate a 'command not found' error for missing test"
    echo "Captured output:"
    echo "$output"
    return 1
  fi
  
  echo "SUCCESS: Test runner correctly failed (return 1) when executing a missing test function"
  return 0
}