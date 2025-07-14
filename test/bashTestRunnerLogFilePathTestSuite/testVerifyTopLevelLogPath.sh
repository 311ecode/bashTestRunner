#!/usr/bin/env bash
testVerifyTopLevelLogPath() {
  echo "Verifying session directory path is reported for top-level calls"
  
  local test_functions=(
    "testLogFilePathSimplePass"
  )
  
  local ignored_tests=()
  
  # Create a temporary file for capturing output
  local temp_output=$(mktemp)
  
  # Save current environment variables
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  
  # Clear environment to simulate top-level call
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  
  # Run bashTestRunner in a subshell to isolate environment
  (
    bashTestRunner test_functions ignored_tests
  ) > "$temp_output" 2>&1
  local result=$?
  
  # Restore environment variables
  if [[ -n "$saved_session" ]]; then
    export BASH_TEST_RUNNER_SESSION="$saved_session"
  fi
  if [[ -n "$saved_nested" ]]; then
    export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"
  fi
  
  # Read the captured output
  local output=$(cat "$temp_output")
  rm -f "$temp_output"
  
  # Check if output contains "Session directory:" line
  if ! echo "$output" | grep -q "Session directory: /tmp/bashTestRunnerSessions/"; then
    echo "ERROR: Top-level call should report session directory path"
    echo "Captured output:"
    echo "$output"
    return 1
  fi
  
  # Check if output contains "Main log file:" line
  if ! echo "$output" | grep -q "Main log file: /tmp/bashTestRunnerSessions/.*main\.log"; then
    echo "ERROR: Top-level call should report main log file path"
    echo "Captured output:"
    echo "$output"
    return 1
  fi
  
  echo "SUCCESS: Top-level call correctly reports session directory and main log file paths"
  return 0
}