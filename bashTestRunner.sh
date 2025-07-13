#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.

bashTestRunner() {
  # Get array references for inputs
  local -n test_functions_ref=$1
  local -n ignored_tests_ref=$2
  local testPwd="$(pwd)"
  
  # Generate a unique identifier for this test run
  local run_id=$(date +%s%N | sha256sum | head -c 8)
  
  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: bashTestRunner called with run_id=$run_id" >&2
    echo "DEBUG: test_functions_ref name=$1, ignored_tests_ref name=$2" >&2
    echo "DEBUG: Test functions: ${test_functions_ref[*]}" >&2
    echo "DEBUG: Ignored tests: ${ignored_tests_ref[*]}" >&2
    echo "DEBUG: Current BASH_TEST_RUNNER_LOG: ${BASH_TEST_RUNNER_LOG:-unset}" >&2
    echo "DEBUG: Current BASH_TEST_RUNNER_LOG_NESTED: ${BASH_TEST_RUNNER_LOG_NESTED:-unset}" >&2
  fi
  
  # Create uniquely named global arrays
  declare -ga "results_$run_id"
  declare -ga "passing_ignored_tests_$run_id"
  declare -gA "metrics_$run_id"
  declare -gA "suite_durations_$run_id"  # For test suite durations
  
  # Determine log file and nesting level
  local log_file
  local is_nested=false
  if [[ -n "${BASH_TEST_RUNNER_LOG}" ]]; then
    # We're in a nested call - reuse the existing log file
    log_file="${BASH_TEST_RUNNER_LOG}"
    is_nested=true
    # Set the nested flag to suppress log file path printing in summary
    export BASH_TEST_RUNNER_LOG_NESTED=1
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Detected nested call, reusing log file: $log_file" >&2
    fi
  else
    # We're in a top-level call - create new log file
    log_file=$(mktemp /tmp/bashTestRunner.XXXXXX.log)
    export BASH_TEST_RUNNER_LOG="${log_file}"
    # Ensure the nested flag is unset for top-level calls
    unset BASH_TEST_RUNNER_LOG_NESTED
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Top-level call, created new log file: $log_file" >&2
    fi
  fi
  
  echo "======================================" | tee -a "${log_file}"
  echo "Starting test suite with ${#test_functions_ref[@]} tests" | tee -a "${log_file}"
  echo "(Plus ${#ignored_tests_ref[@]} ignored tests)" | tee -a "${log_file}"
  echo "======================================" | tee -a "${log_file}"
  echo "" | tee -a "${log_file}"
  
  # Execute all tests and collect results
  bashTestRunner-executeTests "$1" "$2" "$run_id" "$testPwd" "${log_file}"
  
  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: Metrics after execution for run_id=$run_id:" >&2
    eval "for key in \"\${!metrics_$run_id[@]}\"; do echo \"DEBUG:   \$key = \${metrics_$run_id[\$key]}\" >&2; done"
  fi
  
  # Call the summary function with all collected data
  bashTestRunner-printSummary "results_$run_id" "passing_ignored_tests_$run_id" "metrics_$run_id" "$1" "suite_durations_$run_id" "${log_file}"
  
  # Get the final status BEFORE cleaning up arrays
  bashTestRunner-evaluateStatus "metrics_${run_id}"
  local final_status=$?
  
  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: bashTestRunner final_status=$final_status for run_id=$run_id" >&2
    echo "DEBUG: Metrics at evaluation:" >&2
    local metric_var
    for metric_var in ignored_tests_count ignored_passed passed_tests failed_tests counted_tests total_duration ignored_failed; do
        local var_name="metrics_${run_id}[${metric_var}]"
        eval "echo \"DEBUG:   ${metric_var} = \${metrics_${run_id}[${metric_var}]}\" >&2"
    done
  fi
  
  # Clean up environment variables if this was the top-level call
  if [[ "$is_nested" == false ]]; then
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Top-level call finished, cleaning up environment variables" >&2
    fi
    unset BASH_TEST_RUNNER_LOG
    unset BASH_TEST_RUNNER_LOG_NESTED
  fi
  
  return $final_status
}