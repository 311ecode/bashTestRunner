#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
bashTestRunner-printSummary() {
  local -n results_ref=$1
  local -n passing_ignored_tests_ref=$2
  local -n metrics_ref=$3
  local -n test_functions_ref=$4
  local -n suite_durations_ref=$5
  local log_file=$6
  
  local formatted_total_duration=$(printf "%.3f" "${metrics_ref[total_duration]}")
  
  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: printSummary called with:" >&2
    echo "DEBUG:   Total test functions: ${#test_functions_ref[@]}" >&2
    echo "DEBUG:   metrics[counted_tests]: ${metrics_ref[counted_tests]}" >&2
    echo "DEBUG:   metrics[passed_tests]: ${metrics_ref[passed_tests]}" >&2
    echo "DEBUG:   metrics[failed_tests]: ${metrics_ref[failed_tests]}" >&2
    echo "DEBUG:   metrics[ignored_tests_count]: ${metrics_ref[ignored_tests_count]}" >&2
    echo "DEBUG:   BASH_TEST_RUNNER_LOG_NESTED: ${BASH_TEST_RUNNER_LOG_NESTED:-unset}" >&2
  fi
  
  echo "======================================" | tee -a "$log_file"
  echo "TEST SUMMARY" | tee -a "$log_file"
  echo "======================================" | tee -a "$log_file"
  echo "Total tests: ${metrics_ref[counted_tests]}" | tee -a "$log_file"
  echo "Passed: ${metrics_ref[passed_tests]}" | tee -a "$log_file"
  echo "Failed: ${metrics_ref[failed_tests]}" | tee -a "$log_file"
  echo "Ignored tests: ${metrics_ref[ignored_tests_count]} (Passed: ${metrics_ref[ignored_passed]}, Failed: ${metrics_ref[ignored_failed]})" | tee -a "$log_file"
  echo "Total time: ${formatted_total_duration}s" | tee -a "$log_file"
  echo "" | tee -a "$log_file"
  
  echo "Detailed results:" | tee -a "$log_file"
  
  # Print all individual test results
  for result in "${results_ref[@]}"; do
    echo " - $result" | tee -a "$log_file"
  done
  
  # List all test suites with their total execution times
  echo "" | tee -a "$log_file"
  echo "Test functions:" | tee -a "$log_file"
  for test_func in "${!suite_durations_ref[@]}"; do
    local duration=$(printf "%.3f" "${suite_durations_ref[$test_func]}")
    echo " - $test_func (${duration}s)" | tee -a "$log_file"
  done
  
  if [ ${#passing_ignored_tests_ref[@]} -gt 0 ]; then
    echo "" | tee -a "$log_file"
    echo "RECOMMENDATION:" | tee -a "$log_file"
    echo "The following ignored tests are now PASSING:" | tee -a "$log_file"
    for passing_test in "${passing_ignored_tests_ref[@]}"; do
      echo " - $passing_test" | tee -a "$log_file"
    done
  fi
  
  echo "" | tee -a "$log_file"
  echo "FINAL STATUS:" | tee -a "$log_file"
  
  if [ "${metrics_ref[failed_tests]}" -gt 0 ]; then
    echo "FAIL: Test suite completed with ${metrics_ref[failed_tests]} failed tests" | tee -a "$log_file"
  else
    echo "PASS: All ${metrics_ref[passed_tests]} tests passed successfully" | tee -a "$log_file"
  fi
  
  echo "======================================" | tee -a "$log_file"
  
  # Print log file path for top-level (non-nested) runs only
  # Check if we're NOT in a nested run
  if [[ -z "${BASH_TEST_RUNNER_LOG_NESTED}" ]]; then
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: This is a top-level run, printing log file path" >&2
    fi
    echo "Log file: $log_file" | tee -a "$log_file"
  else
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: This is a nested run, NOT printing log file path" >&2
    fi
  fi
}