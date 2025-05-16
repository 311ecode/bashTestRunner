bashTestRunner() {
  # Get array references for inputs
  local -n test_functions_ref=$1
  local -n ignored_tests_ref=$2
  
  # Generate a unique identifier for this test run
  local run_id=$(date +%s%N | sha256sum | head -c 8)
  
  # Create uniquely named global arrays
  declare -ga "results_$run_id"
  declare -ga "passing_ignored_tests_$run_id"
  
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
    
    # Run the test function and record results
    if $test_function; then
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
    
    local test_time_end=$(date +%s.%N)
    local test_duration=$(echo "$test_time_end - $test_time_start" | bc)
    local formatted_duration=$(printf "%.3f" $test_duration)
    
    # Store result in the uniquely named array
    eval "results_$run_id+=(\"$status: $test_function (${formatted_duration}s)\")"
    
    echo "$status: $test_function completed in ${formatted_duration}s"
    echo "--------------------------------------"
    echo ""
  done
  
  local total_time_end=$(date +%s.%N)
  local total_duration=$(echo "$total_time_end - $total_time_start" | bc)
  
  # Pass the dynamically named arrays to the results function
  bashTestRunner-results "results_$run_id" "passing_ignored_tests_$run_id" \
    "$passed_tests" "$failed_tests" "$ignored_passed" "$ignored_failed" \
    "$counted_tests" "${#ignored_tests_ref[@]}" "$total_duration"
  
  # Clean up our uniquely named arrays
  unset "results_$run_id"
  unset "passing_ignored_tests_$run_id"
  
  return $?
}