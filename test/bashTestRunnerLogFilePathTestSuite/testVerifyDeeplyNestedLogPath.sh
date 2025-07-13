#!/usr/bin/env bash
testVerifyDeeplyNestedLogPath() {
  echo "Verifying deeply nested calls only show one log file path"
  
  # Create level 3 test
  level3Test() {
    echo "Level 3 test"
    return 0
  }
  
  # Create level 2 test that calls level 3
  level2Test() {
    echo "Level 2 test calling level 3"
    local level3_functions=("level3Test")
    local level3_ignored=()
    bashTestRunner level3_functions level3_ignored
    return $?
  }
  
  # Create level 1 test that calls level 2  
  level1Test() {
    echo "Level 1 test calling level 2"
    local level2_functions=("level2Test")
    local level2_ignored=()
    bashTestRunner level2_functions level2_ignored
    return $?
  }
  
  local test_functions=(
    "level1Test"
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
  
  # Should only be 1 log file line despite 3 levels of nesting
  if [[ "$log_file_count" -ne 1 ]]; then
    echo "ERROR: Expected exactly 1 'Log file:' line in deeply nested test, but found $log_file_count"
    echo "Captured output:"
    echo "$output"
    return 1
  fi
  
  echo "SUCCESS: Deeply nested calls correctly show only one log file path"
  return 0
}