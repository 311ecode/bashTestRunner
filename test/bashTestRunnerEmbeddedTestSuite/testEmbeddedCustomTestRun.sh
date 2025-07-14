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
  
  # Save current environment variables
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  
  # Clear environment to simulate top-level call for clean output capture
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  
  # Run the test suite in a subshell to isolate environment and capture output
  local result
  (
    bashTestRunner test_functions ignored_tests
  ) > "$temp_output" 2>&1
  result=$?
  
  # Restore environment variables
  if [[ -n "$saved_session" ]]; then
    export BASH_TEST_RUNNER_SESSION="$saved_session"
  fi
  if [[ -n "$saved_nested" ]]; then
    export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"
  fi
  
  # Read the captured output
  local output
  output=$(cat "$temp_output")
  rm -f "$temp_output"
  
  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: Captured output for verification:" >&2
    echo "$output" >&2
    echo "DEBUG: Return code: $result" >&2
  fi
  
  # Verify the test runner returned failure (since one test failed)
  if [[ $result -ne 1 ]]; then
    echo "ERROR: Test runner should have returned 1, but returned $result"
    return 1
  fi
  
  # Verify the output contains the expected summary - use more specific patterns
  if ! echo "$output" | grep -F "Total tests: 2" >/dev/null; then
    echo "ERROR: Output does not contain 'Total tests: 2'"
    echo "Actual output:"
    echo "$output"
    return 1
  fi
  
  if ! echo "$output" | grep -F "Passed: 1" >/dev/null; then
    echo "ERROR: Output does not contain 'Passed: 1'"
    echo "Actual output:"
    echo "$output"
    return 1
  fi
  
  if ! echo "$output" | grep -F "Failed: 1" >/dev/null; then
    echo "ERROR: Output does not contain 'Failed: 1'"
    echo "Actual output:"
    echo "$output"
    return 1
  fi
  
  echo "Custom test verification passed successfully"
  return 0
}