#!/usr/bin/env bash
testVerifyNestedLogPath() {
  echo "Verifying log file path is NOT reported for nested calls"
  
  local test_functions=(
    "testLogFilePathNestedCall"
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
  
  # Count how many "Log file:" lines appear
  local log_file_count=$(echo "$output" | grep -c "Log file: /tmp/bashTestRunner\..*\.log" || true)
  
  # Should only be 1 log file line (from the top-level call, not from nested calls)
  if [[ "$log_file_count" -ne 1 ]]; then
    echo "ERROR: Expected exactly 1 'Log file:' line, but found $log_file_count"
    echo "Captured output:"
    echo "$output"
    return 1
  fi
  
  echo "SUCCESS: Nested calls correctly suppress log file path reporting"
  return 0
}