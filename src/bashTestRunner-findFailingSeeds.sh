#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.

bashTestRunner-findFailingSeeds() {
  local test_functions_ref_name=$1
  local ignored_tests_ref_name=$2
  local max_attempts=${3:-100}
  local failing_seeds_file=${4:-"./failing-seeds"}
  local execution_log_file=${5:-"./test-executions.log"}
  
  # Get array references for inputs
  local -n test_functions_ref=${test_functions_ref_name}
  local -n ignored_tests_ref=${ignored_tests_ref_name}
  
  echo "Starting failing seed discovery with max $max_attempts attempts"
  echo "Results will be written to: $failing_seeds_file"
  echo "Execution log: $execution_log_file"
  echo ""
  
  # Initialize/clear the files
  > "$failing_seeds_file"
  echo "# Test execution log - $(date)" >> "$execution_log_file"
  echo "# Format: TIMESTAMP | SEED | STATUS | FAILED_TESTS | PASSED_TESTS" >> "$execution_log_file"
  
  local attempt=1
  local failing_seeds_found=0
  
  while [[ $attempt -le $max_attempts ]]; do
    # Generate a random seed
    local random_seed=$(date +%s%N | sha256sum | head -c 12)
    
    echo "Attempt $attempt/$max_attempts with seed: $random_seed"
    
    # Set the seed and run the test
    export BASH_TEST_RUNNER_SEED="$random_seed"
    
    # Create temporary output file
    local temp_output=$(mktemp)
    local temp_session="${BASH_TEST_RUNNER_SESSION:-}"
    local temp_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
    
    # Clear environment for clean run
    unset BASH_TEST_RUNNER_SESSION
    unset BASH_TEST_RUNNER_LOG_NESTED
    
    # Run the test suite and capture result
    local test_result
    (
      bashTestRunner "$test_functions_ref_name" "$ignored_tests_ref_name"
    ) > "$temp_output" 2>&1
    test_result=$?
    
    # Restore environment
    if [[ -n "$temp_session" ]]; then
      export BASH_TEST_RUNNER_SESSION="$temp_session"
    fi
    if [[ -n "$temp_nested" ]]; then
      export BASH_TEST_RUNNER_LOG_NESTED="$temp_nested"
    fi
    
    # Parse the results
    local failed_count=0
    local passed_count=0
    
    if grep -q "Failed: " "$temp_output"; then
      failed_count=$(grep "Failed: " "$temp_output" | head -1 | sed 's/Failed: //' | cut -d' ' -f1)
    fi
    
    if grep -q "Passed: " "$temp_output"; then
      passed_count=$(grep "Passed: " "$temp_output" | head -1 | sed 's/Passed: //' | cut -d' ' -f1)
    fi
    
    # Log this execution
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local status="PASS"
    if [[ $test_result -ne 0 ]]; then
      status="FAIL"
    fi
    
    echo "$timestamp | $random_seed | $status | $failed_count | $passed_count" >> "$execution_log_file"
    
    # If test failed, record the failing seed
    if [[ $test_result -ne 0 ]]; then
      echo "🔥 FOUND FAILING SEED: $random_seed (failed: $failed_count, passed: $passed_count)"
      echo "$random_seed" >> "$failing_seeds_file"
      
      # Also save detailed output for this failing seed
      local detailed_file="${failing_seeds_file}.${random_seed}.detailed"
      cp "$temp_output" "$detailed_file"
      echo "Detailed output saved to: $detailed_file"
      
      ((failing_seeds_found++))
    else
      echo "✅ Seed $random_seed passed (failed: $failed_count, passed: $passed_count)"
    fi
    
    # Clean up temp file
    rm -f "$temp_output"
    
    ((attempt++))
  done
  
  # Unset the seed when done
  unset BASH_TEST_RUNNER_SEED
  
  # Final summary
  echo ""
  echo "======================================="
  echo "FAILING SEED DISCOVERY COMPLETE"
  echo "======================================="
  echo "Total attempts: $max_attempts"
  echo "Failing seeds found: $failing_seeds_found"
  echo "Success rate: $(echo "scale=2; ($max_attempts - $failing_seeds_found) * 100 / $max_attempts" | bc)%"
  echo ""
  echo "Failing seeds written to: $failing_seeds_file"
  echo "Execution log written to: $execution_log_file"
  
  if [[ $failing_seeds_found -gt 0 ]]; then
    echo ""
    echo "Found failing seeds:"
    cat "$failing_seeds_file"
  fi
  
  return $failing_seeds_found
}