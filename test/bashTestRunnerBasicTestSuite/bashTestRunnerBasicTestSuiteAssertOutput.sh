#!/usr/bin/env bash
bashTestRunnerBasicTestSuiteAssertOutput() {
  # Save current environment to restore later
  local saved_debug="${DEBUG:-}"
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"

  # Create a temporary file for capturing output
  local temp_output=$(mktemp)

  # Clear environment to simulate top-level call for clean output capture
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  unset DEBUG

  # Run the test suite in a subshell to isolate environment and capture output
  (
    bashTestRunnerBasicTestSuiteRunner
  ) > "$temp_output" 2>&1

  # Restore environment variables
  if [[ -n "$saved_debug" ]]; then
    export DEBUG="$saved_debug"
  fi
  if [[ -n "$saved_session" ]]; then
    export BASH_TEST_RUNNER_SESSION="$saved_session"
  fi
  if [[ -n "$saved_nested" ]]; then
    export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"
  fi

  # Read the captured output
  local output
  output=$(cat "$temp_output")

  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: Full captured output for validation:" >&2
    echo "$output" >&2
  fi

  # Verify critical output patterns
  local errors=0

  # Check for test results
  if ! echo "$output" | grep -q "PASS.*bashTestRunnerBasicTestSuitePass"; then
    echo "ERROR: Missing pass status for bashTestRunnerBasicTestSuitePass"
    ((errors++))
  fi

  if ! echo "$output" | grep -q "IGNORED.*FAIL.*bashTestRunnerBasicTestSuiteFail"; then
    echo "ERROR: Missing ignored status for bashTestRunnerBasicTestSuiteFail"
    ((errors++))
  fi

  if ! echo "$output" | grep -q "PASS.*bashTestRunnerBasicTestSuiteStringComparison"; then
    echo "ERROR: Missing pass status for bashTestRunnerBasicTestSuiteStringComparison"
    ((errors++))
  fi

  # Check final status - look for FINAL STATUS: followed by PASS on next line
  if ! echo "$output" | grep -A1 "FINAL STATUS:" | grep -q "PASS:"; then
    echo "ERROR: Missing final PASS status"
    ((errors++))
  fi

  # Clean up temp files
  rm -f "$temp_output"

  if [[ "$errors" -gt 0 ]]; then
    echo "Test validation failed with $errors errors"
    return 1
  fi

  echo "All output assertions passed successfully"
  return 0
}
