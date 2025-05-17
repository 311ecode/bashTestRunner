#!/bin/bash

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
  
  local passed_tests=0
  local failed_tests=0
  local ignored_passed=0
  local ignored_failed=0
  local total_time_start=$(date +%s.%N)
  
  echo "======================================"
  echo "Starting test suite with $counted_tests tests"
  echo "(Plus ${#ignored_tests_ref[@]} ignored tests)"
  echo "======================================"
  echo ""
  
  # Run all tests
  for test_function in "${test_functions_ref[@]}"; do
    # Track function/suite execution time
    local suite_time_start=$(date +%s.%N)
    
    # Check if this test is in the ignored list
    local is_ignored=false
    for ignored in "${ignored_tests_ref[@]}"; do
      if [[ "$test_function" == "$ignored" ]]; then
        is_ignored=true
        break
      fi
    done
    
    echo "Running test: $test_function"
    if $is_ignored; then
      echo "(Note: This test will be ignored in final results)"
    fi
    
    # Create result collection arrays for nested tests
    local test_time_start=$(date +%s.%N)
    
    # Save current directory
    local original_dir=$(pwd)
    
    # Create temporary file to save global variables that might be overwritten
    local tmpfile=$(mktemp)
    
    # If these variables exist, save them to our temp file
    if declare -p test_functions &>/dev/null; then
      echo "test_functions_exist=1" >> "$tmpfile"
      declare -p test_functions >> "$tmpfile"
    else
      echo "test_functions_exist=0" >> "$tmpfile"
    fi
    
    if declare -p ignored_tests &>/dev/null; then
      echo "ignored_tests_exist=1" >> "$tmpfile"
      declare -p ignored_tests >> "$tmpfile"
    else
      echo "ignored_tests_exist=0" >> "$tmpfile"
    fi
    
    # Unset the variables to prevent interference with nested tests
    unset test_functions 2>/dev/null || true
    unset ignored_tests 2>/dev/null || true
    
    # Change to the test directory
    cd "$testPwd"
    
    # Execute the test function directly
    $test_function
    local test_result=$?
    
    # Restore original directory
    cd "$original_dir"
    
    # Restore saved variables from our temp file
    source "$tmpfile"
    if [[ "$test_functions_exist" == "1" ]]; then
      eval "$(grep "^test_functions=" "$tmpfile")"
    fi
    
    if [[ "$ignored_tests_exist" == "1" ]]; then
      eval "$(grep "^ignored_tests=" "$tmpfile")"
    fi
    
    # Clean up temp file
    rm -f "$tmpfile"
    
    # Record the test result
    local test_time_end=$(date +%s.%N)
    local test_duration=$(echo "$test_time_end - $test_time_start" | bc)
    local formatted_duration=$(printf "%.3f" $test_duration)
    
    if [[ $test_result -eq 0 ]]; then
      if $is_ignored; then
        local status="IGNORED (PASS)"
        ((ignored_passed++))
        eval "passing_ignored_tests_$run_id+=(\"$test_function\")"
      else
        local status="PASS"
        ((passed_tests++))
      fi
    else
      if $is_ignored; then
        local status="IGNORED (FAIL)"
        ((ignored_failed++))
      else
        local status="FAIL"
        ((failed_tests++))
      fi
    fi
    
    # Store result in the uniquely named array
    eval "results_$run_id+=(\"$status: $test_function (${formatted_duration}s)\")"
    
    # Calculate and store suite total duration
    local suite_time_end=$(date +%s.%N)
    local suite_duration=$(echo "$suite_time_end - $suite_time_start" | bc)
    eval "suite_durations_$run_id[\"$test_function\"]=$suite_duration"
    
    echo "$status: $test_function completed in ${formatted_duration}s"
    echo "--------------------------------------"
    echo ""
  done
  
  local total_time_end=$(date +%s.%N)
  local total_duration=$(echo "$total_time_end - $total_time_start" | bc)
  
  # Create associative array for metrics
  eval "metrics_$run_id=(
    [passed_tests]=$passed_tests
    [failed_tests]=$failed_tests
    [ignored_passed]=$ignored_passed
    [ignored_failed]=$ignored_failed
    [counted_tests]=$counted_tests
    [ignored_tests_count]=${#ignored_tests_ref[@]}
    [total_duration]=$total_duration
  )"
  
  # Call the summary function with all collected data
  bashTestRunner-printSummary "results_$run_id" "passing_ignored_tests_$run_id" "metrics_$run_id" "$1" "suite_durations_$run_id"
  bashTestRunner-evaluateStatus "metrics_$run_id"
  
  # Clean up our uniquely named arrays
  unset "results_$run_id"
  unset "passing_ignored_tests_$run_id"
  unset "metrics_$run_id"
  unset "suite_durations_$run_id"
  
  cd "${testPwd}"

  return $?
}