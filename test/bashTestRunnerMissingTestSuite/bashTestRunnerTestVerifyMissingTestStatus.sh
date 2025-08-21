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

  # Save current environment variables
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  local saved_path="${BASH_TEST_RUNNER_TEST_PATH:-}"

  # Clear environment to simulate top-level call for clean output capture
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  unset BASH_TEST_RUNNER_TEST_PATH

  # Run bashTestRunner in a subshell to isolate environment and capture output
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
  if [[ -n "$saved_path" ]]; then
    export BASH_TEST_RUNNER_TEST_PATH="$saved_path"
  fi

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

  # Verify error message in output (Bash-specific "command not found")
  if ! echo "$output" | grep -q "command not found"; then
    echo "ERROR: Output does not indicate a 'command not found' error for missing test"
    echo "Expected to find 'command not found' in output"
    echo "Captured output:"
    echo "$output"
    return 1
  fi

  # Verify that the test was marked as FAIL - now with hierarchical path
  # The pattern should match the hierarchical format: "FAIL: parentTest->non_existent_test_function_that_does_not_exist"
  if ! echo "$output" | grep -q "FAIL:.*non_existent_test_function_that_does_not_exist"; then
    echo "ERROR: Output does not show the missing test as FAIL with hierarchical path"
    echo "Expected to find 'FAIL: *non_existent_test_function_that_does_not_exist' in output"
    echo "Captured output:"
    echo "$output"
    return 1
  fi

  echo "SUCCESS: Test runner correctly failed (return 1) when executing a missing test function"
  return 0
}
