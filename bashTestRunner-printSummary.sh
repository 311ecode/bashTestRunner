#!/bin/bash
bashTestRunner-printSummary() {
  local -n results_ref=$1
  local -n passing_ignored_tests_ref=$2
  local -n metrics_ref=$3
  
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
  
  for result in "${results_ref[@]}"; do
    echo " - $result"
  done
  
  if [ ${#passing_ignored_tests_ref[@]} -gt 0 ]; then
    echo ""
    echo "RECOMMENDATION:"
    echo "The following ignored tests are now PASSING:"
    for passing_test in "${passing_ignored_tests_ref[@]}"; do
      echo " - $passing_test"
    done
  fi
  
  echo "======================================"
}