#!/usr/bin/env bash
testVerifyTopLevelLogPath() {
  echo "Verifying log file path is reported for top-level calls"
  
  local test_functions=(
    "testLogFilePathSimplePass"
  )
  
  local ignored_tests=()
  
  # Create a temporary file for capturing output
  local temp_output=$(mktemp)
  
  # Save current environment variables
  local saved_log="${BASH_TEST_RUNNER_LOG:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  
  # Clear environment to simulate top-level call
  unset BASH_TEST_RUNNER_LOG
  unset BASH_TEST_RUNNER_LOG_NESTED
  
  # Run bashTestRunner in a subshell to isolate environment
  (
    bashTestRunner test_functions ignored_tests
  ) > "$temp_output" 2>&1
  local result=$?
  
  # Restore environment variables
  if [[ -n "$saved_log" ]]; then
    export BASH_TEST_RUNNER_LOG="$saved_log"
  fi
  if [[ -n "$saved_nested" ]]; then
    export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"
  fi
  
  # Read the captured output
  local output=$(cat "$temp_output")
  rm -f "$temp_output"
  
  # Check if output contains "Log file:" line
  if ! echo "$output" | grep -q "Log file: /tmp/bashTestRunner\..*\.log"; then
    echo "ERROR: Top-level call should report log file path"
    echo "Captured output:"
    echo "$output"
    return 1
  fi
  
  echo "SUCCESS: Top-level call correctly reports log file path"
  return 0
}