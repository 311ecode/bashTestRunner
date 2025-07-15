#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
bashTestRunner-executeTests() {
  local -n test_functions_ref=$1
  local -n ignored_tests_ref=$2
  local run_id=$3
  local testPwd=$4
  local log_file=$5
  local session_dir=$6
  
  local passed_tests=0
  local failed_tests=0
  local ignored_passed=0
  local ignored_failed=0
  local total_time_start=$(date +%s.%N)
  
  local test_function  # Declare as local to prevent pollution in nested calls
  
  # Initialize or increment the global test counter
  if [[ -z "${BASH_TEST_RUNNER_TEST_COUNTER}" ]]; then
    export BASH_TEST_RUNNER_TEST_COUNTER=1
  fi
  
  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: executeTests starting with run_id=$run_id" >&2
    echo "DEBUG: Test functions: ${test_functions_ref[*]}" >&2
    echo "DEBUG: Ignored tests: ${ignored_tests_ref[*]}" >&2
    echo "DEBUG: Test functions count: ${#test_functions_ref[@]}" >&2
    echo "DEBUG: Ignored tests count: ${#ignored_tests_ref[@]}" >&2
    echo "DEBUG: Session directory: $session_dir" >&2
    echo "DEBUG: Test counter starting at: $BASH_TEST_RUNNER_TEST_COUNTER" >&2
  fi
  
  # Apply shuffling if seed is provided
  if [[ -n "${BASH_TEST_RUNNER_SEED}" ]]; then
    echo "Shuffling tests with seed: ${BASH_TEST_RUNNER_SEED}" >> "${log_file}"
    bashTestRunner-shuffleArray test_functions_ref "${BASH_TEST_RUNNER_SEED}"
    echo "Test execution order: ${test_functions_ref[*]}" >> "${log_file}"
    echo "" >> "${log_file}"
  fi
  
  # Run all tests
  for test_function in "${test_functions_ref[@]}"; do
    # Track function/suite execution time
    local suite_time_start=$(date +%s.%N)
    
    # Generate individual test log file name
    local test_number=$(printf "%04d" $BASH_TEST_RUNNER_TEST_COUNTER)
    local random_suffix=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 6)
    local individual_log="${session_dir}/${test_number}-${test_function}-${random_suffix}.log"
    
    # Check if this test is in the ignored list
    local is_ignored=false
    for ignored in "${ignored_tests_ref[@]}"; do
      if [[ "$test_function" == "$ignored" ]]; then
        is_ignored=true
        break
      fi
    done
    
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Running test function: $test_function (ignored=$is_ignored)" >&2
      echo "DEBUG: Individual log file: $individual_log" >&2
      echo "DEBUG: Test counter: $BASH_TEST_RUNNER_TEST_COUNTER" >&2
    fi
    
    # Create individual log file and start tail process for it
    touch "$individual_log"
    tail -f -n +1 "$individual_log" &
    local tail_pid=$!
    
    echo "Running test: $test_function" >> "$individual_log"
    
    if $is_ignored; then
      echo "(Note: This test will be ignored in final results)" >> "$individual_log"
    fi
    
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
    
    # Execute the test function with output redirected to both main and individual logs
    $test_function >> "$individual_log" 2>&1
    local test_result=$?
    
    # Also append to main log
    cat "$individual_log" >> "$log_file"
    
    # Kill the tail process for this individual test
    kill $tail_pid 2>/dev/null || true
    
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Test $test_function returned exit code: $test_result" >&2
      echo "DEBUG: Killed tail PID $tail_pid for individual log" >&2
    fi
    
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
    
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Test result for $test_function: status=$status, passed_tests=$passed_tests, failed_tests=$failed_tests" >&2
    fi
    
    # Store result in the uniquely named array
    eval "results_$run_id+=(\"$status: $test_function (${formatted_duration}s)\")"
    
    # Calculate and store suite total duration
    local suite_time_end=$(date +%s.%N)
    local suite_duration=$(echo "$suite_time_end - $suite_time_start" | bc)
    eval "suite_durations_$run_id[\"$test_function\"]=$suite_duration"
    
    # Log completion to both logs
    echo "$status: $test_function completed in ${formatted_duration}s" >> "$log_file"
    echo "$status: $test_function completed in ${formatted_duration}s" >> "$individual_log"
    echo "--------------------------------------" >> "$log_file"
    echo "--------------------------------------" >> "$individual_log"
    echo "" >> "$log_file"
    echo "" >> "$individual_log"
    
    # Increment the global test counter for next test
    ((BASH_TEST_RUNNER_TEST_COUNTER++))
  done
  
  local total_time_end=$(date +%s.%N)
  local total_duration=$(echo "$total_time_end - $total_time_start" | bc)
  
  # Calculate counted tests (non-ignored tests)
  local counted_tests=$((passed_tests + failed_tests))
  
  # Create associative array for metrics using declare instead of eval
  declare -gA "metrics_$run_id"
  eval "metrics_$run_id[passed_tests]=$passed_tests"
  eval "metrics_$run_id[failed_tests]=$failed_tests"
  eval "metrics_$run_id[ignored_passed]=$ignored_passed"
  eval "metrics_$run_id[ignored_failed]=$ignored_failed"
  eval "metrics_$run_id[counted_tests]=$counted_tests"
  eval "metrics_$run_id[ignored_tests_count]=${#ignored_tests_ref[@]}"
  eval "metrics_$run_id[total_duration]=$total_duration"
  
  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: Final metrics for run_id $run_id:" >&2
    eval "for key in \"\${!metrics_$run_id[@]}\"; do echo \"DEBUG:   \$key = \${metrics_$run_id[\$key]}\" >&2; done"
  fi
}