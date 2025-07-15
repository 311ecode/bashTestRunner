#!/usr/bin/env bash
testVerifyIgnoredLogFileNaming() {
  echo "Verifying that ignored tests have -IGNORED suffix in their log file names"
  
  # Define test functions for verification
  ignoredNamingTestPass() {
    echo "This test will pass but be ignored"
    return 0
  }
  
  ignoredNamingTestFail() {
    echo "This test will fail but be ignored"
    return 1
  }
  
  ignoredNamingTestRegular() {
    echo "This test will run normally"
    return 0
  }
  
  local test_functions=(
    "ignoredNamingTestPass"
    "ignoredNamingTestFail"
    "ignoredNamingTestRegular"
  )
  
  local ignored_tests=(
    "ignoredNamingTestPass"
    "ignoredNamingTestFail"
  )
  
  # Save current environment variables
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  
  # Clear environment to simulate top-level call
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  
  # Create temp file for output capture
  local temp_output=$(mktemp)
  
  # Run bashTestRunner and capture the session directory from output
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
  
  # Extract the session directory from the output
  local session_dir=$(grep "Session directory:" "$temp_output" | awk '{print $3}')
  rm -f "$temp_output"
  
  if [[ -z "$session_dir" || ! -d "$session_dir" ]]; then
    echo "ERROR: Could not find or access session directory: $session_dir"
    return 1
  fi
  
  echo "Checking log files in session directory: $session_dir"
  
  # Check for ignored test log files with -IGNORED suffix
  local ignored_pass_logs=$(find "$session_dir" -name "*ignoredNamingTestPass-IGNORED-*.log" | wc -l)
  local ignored_fail_logs=$(find "$session_dir" -name "*ignoredNamingTestFail-IGNORED-*.log" | wc -l)
  
  if [[ $ignored_pass_logs -ne 1 ]]; then
    echo "ERROR: Expected exactly 1 log file for ignoredNamingTestPass with -IGNORED suffix, found $ignored_pass_logs"
    echo "Log files in session directory:"
    ls -la "$session_dir"/*.log 2>/dev/null || echo "No log files found"
    return 1
  fi
  
  if [[ $ignored_fail_logs -ne 1 ]]; then
    echo "ERROR: Expected exactly 1 log file for ignoredNamingTestFail with -IGNORED suffix, found $ignored_fail_logs"
    echo "Log files in session directory:"
    ls -la "$session_dir"/*.log 2>/dev/null || echo "No log files found"
    return 1
  fi
  
  # Check for regular test log file WITHOUT -IGNORED suffix
  local regular_logs=$(find "$session_dir" -name "*ignoredNamingTestRegular-*.log" ! -name "*-IGNORED-*" | wc -l)
  
  if [[ $regular_logs -ne 1 ]]; then
    echo "ERROR: Expected exactly 1 log file for ignoredNamingTestRegular without -IGNORED suffix, found $regular_logs"
    echo "Log files in session directory:"
    ls -la "$session_dir"/*.log 2>/dev/null || echo "No log files found"
    return 1
  fi
  
  # Verify that regular test does NOT have -IGNORED in its name
  local regular_ignored_logs=$(find "$session_dir" -name "*ignoredNamingTestRegular*-IGNORED-*.log" | wc -l)
  
  if [[ $regular_ignored_logs -ne 0 ]]; then
    echo "ERROR: Found $regular_ignored_logs log files for ignoredNamingTestRegular with -IGNORED suffix (should be 0)"
    echo "Log files in session directory:"
    ls -la "$session_dir"/*.log 2>/dev/null || echo "No log files found"
    return 1
  fi
  
  # Additional verification: check that the content matches expectations
  local ignored_pass_file=$(find "$session_dir" -name "*ignoredNamingTestPass-IGNORED-*.log" | head -1)
  local ignored_fail_file=$(find "$session_dir" -name "*ignoredNamingTestFail-IGNORED-*.log" | head -1)
  local regular_file=$(find "$session_dir" -name "*ignoredNamingTestRegular-*.log" ! -name "*-IGNORED-*" | head -1)
  
  # Verify ignored test files contain the "ignored" note
  if ! grep -q "(Note: This test will be ignored in final results)" "$ignored_pass_file"; then
    echo "ERROR: Ignored pass test log file missing expected note about being ignored"
    return 1
  fi
  
  if ! grep -q "(Note: This test will be ignored in final results)" "$ignored_fail_file"; then
    echo "ERROR: Ignored fail test log file missing expected note about being ignored"
    return 1
  fi
  
  # Verify regular test file does NOT contain the ignored note
  if grep -q "(Note: This test will be ignored in final results)" "$regular_file"; then
    echo "ERROR: Regular test log file contains ignored note when it shouldn't"
    return 1
  fi
  
  echo "SUCCESS: All log file naming verified correctly"
  echo "  - Ignored tests have -IGNORED suffix in log file names"
  echo "  - Regular tests do not have -IGNORED suffix"
  echo "  - Log file contents match expected patterns"
  
  return 0
}