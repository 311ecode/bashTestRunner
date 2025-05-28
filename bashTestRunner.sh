#!/bin/bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.

bashTestRunner() {
  # Get array references for inputs
  local -n test_functions_ref=$1
  local -n ignored_tests_ref=$2
  local testPwd="$(pwd)"
  
  # Generate a unique identifier for this test run
  local run_id=$(date +%s%N | sha256sum | head -c 8)
  
  # Create uniquely named global arrays
  declare -ga "results_$run_id"
  declare -ga "passing_ignored_tests_$run_id"
  declare -gA "metrics_$run_id"
  declare -gA "suite_durations_$run_id"  # For test suite durations
  
  # Calculate non-ignored tests count
  local counted_tests=0
  for test in "${test_functions_ref[@]}"; do
    local is_ignored=false
    for ignored in "${ignored_tests_ref[@]}"; do
      if [[ "$test" == "$ignored" ]]; then
        is_ignored=true
        break
      fi
    done
    if ! $is_ignored; then
      ((counted_tests++))
    fi
  done
  
  echo "======================================"
  echo "Starting test suite with $counted_tests tests"
  echo "(Plus ${#ignored_tests_ref[@]} ignored tests)"
  echo "======================================"
  echo ""
  
  # Execute all tests and collect results
  bashTestRunner-executeTests "$1" "$2" "$run_id" "$testPwd"
  
  # Call the summary function with all collected data
  bashTestRunner-printSummary "results_$run_id" "passing_ignored_tests_$run_id" "metrics_$run_id" "$1" "suite_durations_$run_id"
  bashTestRunner-evaluateStatus "metrics_$run_id"
  local final_status=$?
  
  # Clean up our uniquely named arrays
  unset "results_$run_id"
  unset "passing_ignored_tests_$run_id"
  unset "metrics_$run_id"
  unset "suite_durations_$run_id"
  
  cd "${testPwd}"
  return $final_status
}

