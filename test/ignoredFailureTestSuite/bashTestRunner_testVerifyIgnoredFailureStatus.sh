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
  
  # Save current environment variables
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  
  # Clear environment to simulate top-level call for clean output capture
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  
  # Run bash test runner in a subshell to isolate environment and capture output
  local return_code
  (
    bashTestRunner test_functions ignored_tests
  ) > "$temp_output" 2>&1
  return_code=$?
  
  # Restore environment variables
  if [[ -n "$saved_session" ]]; then
    export BASH_TEST_RUNNER_SESSION="$saved_session"
  fi
  if [[ -n "$saved_nested" ]]; then
    export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"
  fi
  
  # Read the captured output
  local output=$(cat "$temp_output")
  
  if [[ -n "$DEBUG" ]]; then
    echo "=== Test Runner Output ===" >&2
    echo "$output" >&2
    echo "=== End Output ===" >&2
    echo "bashTestRunner returned: $return_code" >&2
  fi
  
  # Clean up temp file
  rm -f "$temp_output"
  
  # Verify the output contains expected information
  if ! echo "$output" | grep -q "IGNORED (FAIL): bashTestRunner_testIgnoredFailureSuiteFail"; then
    echo "ERROR: Output doesn't show the ignored failing test"
    echo "Expected pattern: 'IGNORED (FAIL): bashTestRunner_testIgnoredFailureSuiteFail'"
    echo "Actual output:"
    echo "$output"
    return 1
  fi
  
  # Check for final PASS status
  if ! echo "$output" | grep -q "FINAL STATUS:" && echo "$output" | grep -q "PASS: All"; then
    echo "ERROR: Output doesn't show final PASS status"
    echo "Actual output:"
    echo "$output"
    return 1
  fi
  
  # Verify the runner returned success (0) despite having an ignored failing test
  if [[ "$return_code" -ne 0 ]]; then
    echo "ERROR: Test runner returned non-zero ($return_code) despite failing test being ignored"
    return 1
  else
    echo "SUCCESS: Test runner correctly returned 0 (success) status with ignored failing test"
    return 0
  fi
}