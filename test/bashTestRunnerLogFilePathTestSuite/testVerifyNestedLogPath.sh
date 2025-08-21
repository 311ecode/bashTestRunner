#!/usr/bin/env bash
testVerifyNestedLogPath() {
  echo "Verifying session directory path is NOT reported for nested calls"

  local test_functions=(
    "testLogFilePathNestedCall"
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

  # Count how many "Session directory:" lines appear
  local session_dir_count=$(echo "$output" | grep -c "Session directory: /tmp/bashTestRunnerSessions/" || true)

  # Should only be 1 session directory line (from the top-level call, not from nested calls)
  if [[ "$session_dir_count" -ne 1 ]]; then
    echo "ERROR: Expected exactly 1 'Session directory:' line, but found $session_dir_count"
    echo "Captured output:"
    echo "$output"
    return 1
  fi

  # Count how many "Main log file:" lines appear
  local main_log_count=$(echo "$output" | grep -c "Main log file: /tmp/bashTestRunnerSessions/.*main\.log" || true)

  # Should only be 1 main log file line (from the top-level call, not from nested calls)
  if [[ "$main_log_count" -ne 1 ]]; then
    echo "ERROR: Expected exactly 1 'Main log file:' line, but found $main_log_count"
    echo "Captured output:"
    echo "$output"
    return 1
  fi

  echo "SUCCESS: Nested calls correctly suppress session directory path reporting"
  return 0
}
