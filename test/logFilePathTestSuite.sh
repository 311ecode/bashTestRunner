#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Test suite to verify log file path is correctly reported

# Simple passing test for top-level execution
testLogFilePathSimplePass() {
  echo "Simple passing test"
  return 0
}

# Simple failing test for top-level execution  
testLogFilePathSimpleFail() {
  echo "Simple failing test"
  return 1
}

# Test that calls another bashTestRunner (nested execution)
testLogFilePathNestedCall() {
  echo "Testing nested bashTestRunner call"
  
  # Create inner test functions
  innerTestPass() {
    echo "Inner test passing"
    return 0
  }
  
  innerTestFail() {
    echo "Inner test failing"
    return 1
  }
  
  local inner_functions=(
    "innerTestPass"
    "innerTestFail"
  )
  
  local inner_ignored=(
    "innerTestFail"
  )
  
  # This should be a nested call and should NOT print log file path
  bashTestRunner inner_functions inner_ignored
  return $?
}

# Test that verifies log file path is reported for top-level calls
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

# Test that verifies log file path is NOT reported for nested calls
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

# Test that verifies multiple levels of nesting only show one log file path
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

# Main function to run the log file path test suite
logFilePathTestSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C
  
  local test_functions=(
    "testLogFilePathSimplePass"
    "testLogFilePathSimpleFail"  
    "testLogFilePathNestedCall"
    "testVerifyTopLevelLogPath"
    "testVerifyNestedLogPath"
    "testVerifyDeeplyNestedLogPath"
  )
  
  local ignored_tests=(
    "testLogFilePathSimpleFail"  # Ignore the failing test
  )
  
  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}

# Execute the test suite if this script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  logFilePathTestSuite
fi