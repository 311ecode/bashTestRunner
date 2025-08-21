#!/usr/bin/env bash
testVerifyReturnStatus() {
  echo "Verifying that the test runner returns non-zero status when tests fail"

  # Create test functions for this verification
  local test_functions=(
    "bashTestRunner_testFailureStatusPass"
    "bashTestRunner_testFailureStatusFail"
  )

  # No tests are ignored - we want the failure to count
  local ignored_tests=()

  # Create a temporary file for capturing output
  local temp_output=$(mktemp)

  # Run bash test runner and capture output and exit status
  bashTestRunner test_functions ignored_tests > "$temp_output" 2>&1
  local return_code=$?

  # Display the output if debug is enabled
  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: Inner test runner output:" >&2
    cat "$temp_output" >&2
  fi

  rm -f "$temp_output"

  echo "bashTestRunner returned: $return_code"

  # Verify the runner returned a non-zero value due to the failed test
  if [[ "$return_code" -eq 0 ]]; then
    echo "ERROR: Test runner returned 0 (success) despite having a failing test"
    return 1
  else
    echo "SUCCESS: Test runner correctly returned non-zero ($return_code) status"
    return 0
  fi
}
