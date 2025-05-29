#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
bashTestRunner-printSummary() {
  local -n results_ref=$1
  local -n passing_ignored_tests_ref=$2
  local -n metrics_ref=$3
  local -n test_functions_ref=$4
  local -n suite_durations_ref=$5
  
  local formatted_total_duration=$(printf "%.3f" "${metrics_ref[total_duration]}")
  
  echo "======================================"
  echo "TEST SUMMARY"
  echo "======================================"
  echo "Total tests: ${metrics_ref[counted_tests]}"
  echo "Passed: ${metrics_ref[passed_tests]}"
  echo "Failed: ${metrics_ref[failed_tests]}"
  echo "Ignored tests: ${metrics_ref[ignored_tests_count]} (Passed: ${metrics_ref[ignored_passed]}, Failed: ${metrics_ref[ignored_failed]})"
  echo "Total time: ${formatted_total_duration}s"
  echo ""
  echo "Detailed results:"
  
  # Print all individual test results
  for result in "${results_ref[@]}"; do
    echo " - $result"
  done
  
  # List all test suites with their total execution times
  echo ""
  echo "Test functions:"
  for test_func in "${!suite_durations_ref[@]}"; do
    local duration=$(printf "%.3f" "${suite_durations_ref[$test_func]}")
    echo " - $test_func (${duration}s)"
  done
  
  if [ ${#passing_ignored_tests_ref[@]} -gt 0 ]; then
    echo ""
    echo "RECOMMENDATION:"
    echo "The following ignored tests are now PASSING:"
    for passing_test in "${passing_ignored_tests_ref[@]}"; do
      echo " - $passing_test"
    done
  fi
  
  echo ""
  echo "FINAL STATUS:"
  
  if [ "${metrics_ref[failed_tests]}" -gt 0 ]; then
    echo "FAIL: Test suite completed with ${metrics_ref[failed_tests]} failed tests"
  else
    echo "PASS: All ${metrics_ref[passed_tests]} tests passed successfully"
  fi
  
  echo "======================================"
}
