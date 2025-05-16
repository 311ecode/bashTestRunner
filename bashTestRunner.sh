#!/bin/bash

bashTestRunner() {
  # Get array references
  local -n test_functions_ref=$1
  local -n ignored_tests_ref=$2
  
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
  
  # Array to store ignored tests that are now passing
  declare -a passing_ignored_tests
  
  echo "======================================"
  echo "Starting test suite with $counted_tests tests"
  echo "(Plus ${#ignored_tests_ref[@]} ignored tests)"
  echo "======================================"
  echo ""
  
  # Results array to store test results
  declare -a results
  
  for test_function in "${test_functions_ref[@]}"; do
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
    
    local test_time_start=$(date +%s.%N)
    
    # Run the test function
    if $test_function; then
      if $is_ignored; then
        local status="IGNORED (PASS)"
        ((ignored_passed++))
        passing_ignored_tests+=("$test_function")
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
    
    local test_time_end=$(date +%s.%N)
    local test_duration=$(echo "$test_time_end - $test_time_start" | bc)
    local formatted_duration=$(printf "%.3f" $test_duration)
    
    results+=("$status: $test_function (${formatted_duration}s)")
    
    echo "$status: $test_function completed in ${formatted_duration}s"
    echo "--------------------------------------"
    echo ""
  done
  
  local total_time_end=$(date +%s.%N)
  local total_duration=$(echo "$total_time_end - $total_time_start" | bc)
  
  bashTestRunner-results results passing_ignored_tests "$passed_tests" "$failed_tests" \
    "$ignored_passed" "$ignored_failed" "$counted_tests" "${#ignored_tests_ref[@]}" "$total_duration"
  
  return $?
}