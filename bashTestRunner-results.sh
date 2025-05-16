#!/bin/bash

bashTestRunner-results() {
  local -n results_ref=$1
  local -n passing_ignored_tests_ref=$2
  local passed_tests=$3
  local failed_tests=$4
  local ignored_passed=$5
  local ignored_failed=$6
  local counted_tests=$7
  local ignored_tests_count=$8
  local total_duration=$9
  
  local formatted_total_duration=$(printf "%.3f" $total_duration)
  
  echo "======================================"
  echo "TEST SUMMARY"
  echo "======================================"
  echo "Total tests: $counted_tests"
  echo "Passed: $passed_tests"
  echo "Failed: $failed_tests"
  echo "Ignored tests: $ignored_tests_count (Passed: $ignored_passed, Failed: $ignored_failed)"
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
  
  if [ $failed_tests -gt 0 ]; then
    return 1
  else
    return 0
  fi
}