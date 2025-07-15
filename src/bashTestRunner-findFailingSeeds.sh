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
  
  echo "======================================="
  echo "FAILING SEED DISCOVERY STARTED"
  echo "======================================="
  echo "Max attempts: $max_attempts"
  echo "Test suites: ${#test_functions_ref[@]}"
  echo "Results file: $failing_seeds_file"
  echo "Execution log: $execution_log_file"
  echo ""
  
  # Initialize/clear the files
  > "$failing_seeds_file"
  echo "# Test execution log - $(date)" >> "$execution_log_file"
  echo "# Format: TIMESTAMP | SEED | STATUS | FAILED_TESTS | PASSED_TESTS | FAILING_TESTS" >> "$execution_log_file"
  
  local attempt=1
  local failing_seeds_found=0
  local passing_runs=0
  
  while [[ $attempt -le $max_attempts ]]; do
    # Generate a random seed
    local random_seed=$(date +%s%N | sha256sum | head -c 12)
    
    echo "======================================="
    echo "ATTEMPT $attempt/$max_attempts"
    echo "======================================="
    echo "Seed: $random_seed"
    echo "Time: $(date)"
    echo ""
    
    # Set the seed and run the test
    export BASH_TEST_RUNNER_SEED="$random_seed"
    
    # Save current environment to restore later
    local temp_session="${BASH_TEST_RUNNER_SESSION:-}"
    local temp_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
    
    # Clear environment for clean run
    unset BASH_TEST_RUNNER_SESSION
    unset BASH_TEST_RUNNER_LOG_NESTED
    
    # Run the test suite and capture result - show output in real-time
    local test_result
    echo "Running test suite with seed $random_seed..."
    echo "---------------------------------------"
    bashTestRunner "$test_functions_ref_name" "$ignored_tests_ref_name"
    test_result=$?
    echo "---------------------------------------"
    
    # Restore environment
    if [[ -n "$temp_session" ]]; then
      export BASH_TEST_RUNNER_SESSION="$temp_session"
    fi
    if [[ -n "$temp_nested" ]]; then
      export BASH_TEST_RUNNER_LOG_NESTED="$temp_nested"
    fi
    
    # Parse the results from the most recent session
    local failed_count=0
    local passed_count=0
    local failing_tests=""
    
    # Find the most recent main.log by modification time
    local latest_main_log=$(find /tmp/bashTestRunnerSessions -name "main.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
    if [[ -n "$latest_main_log" ]]; then
      local latest_session_dir=$(dirname "$latest_main_log")
      
      # Extract the last TEST SUMMARY content
      local last_summary=$(tail -n 500 "$latest_main_log" | awk '/^TEST SUMMARY$/{found=1; next} found && /^=+$/{exit} found {print $0}')
      
      if [[ -n "$last_summary" ]]; then
        failed_count=$(echo "$last_summary" | grep "^Failed: " | sed 's/^Failed: //' | cut -d' ' -f1 || echo 0)
        passed_count=$(echo "$last_summary" | grep "^Passed: " | sed 's/^Passed: //' | cut -d' ' -f1 || echo 0)
      fi
      
      # If failed, extract failing test names from the last detailed results
      if [[ $test_result -ne 0 ]]; then
        failing_tests=$(tail -n 500 "$latest_main_log" | grep ' - FAIL: ' | sed 's/ - FAIL: //' | sed 's/ (.*//' | head -3 | paste -sd ',' - || echo "")
      fi
    fi
    
    # Log this execution
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local status="PASS"
    if [[ $test_result -ne 0 ]]; then
      status="FAIL"
    fi
    
    echo "$timestamp | $random_seed | $status | $failed_count | $passed_count | $failing_tests" >> "$execution_log_file"
    
    # Report result
    echo ""
    echo "RESULT: $status (exit code: $test_result)"
    echo "Failed tests: $failed_count"
    echo "Passed tests: $passed_count"
    
    # If test failed, record the failing seed
    if [[ $test_result -ne 0 ]]; then
      echo ""
      echo "🔥 FOUND FAILING SEED: $random_seed"
      echo "$random_seed" >> "$failing_seeds_file"
      
      # Also save detailed output for this failing seed
      if [[ -n "$latest_session_dir" && -f "$latest_session_dir/main.log" ]]; then
        local detailed_file="${failing_seeds_file}.${random_seed}.detailed"
        cp "$latest_session_dir/main.log" "$detailed_file"
        echo "Detailed output saved to: $detailed_file"
      fi
      
      ((failing_seeds_found++))
      echo "Total failing seeds found so far: $failing_seeds_found"
    else
      echo ""
      echo "✅ SEED PASSED"
      ((passing_runs++))
    fi
    
    # Show running statistics
    echo ""
    echo "RUNNING STATS:"
    echo "  Attempts completed: $attempt"
    echo "  Passing runs: $passing_runs"
    echo "  Failing seeds found: $failing_seeds_found"
    if [[ $attempt -gt 0 ]]; then
      local success_rate=$(echo "scale=1; $passing_runs * 100 / $attempt" | bc)
      echo "  Success rate: ${success_rate}%"
    fi
    echo ""
    
    ((attempt++))
    
    # Small delay to make output readable
    sleep 1
  done
  
  # Unset the seed when done
  unset BASH_TEST_RUNNER_SEED
  
  # Final summary
  echo ""
  echo "======================================="
  echo "FAILING SEED DISCOVERY COMPLETE"
  echo "======================================="
  echo "Total attempts: $max_attempts"
  echo "Passing runs: $passing_runs"
  echo "Failing seeds found: $failing_seeds_found"
  echo "Success rate: $(echo "scale=2; $passing_runs * 100 / $max_attempts" | bc)%"
  echo ""
  echo "Results saved to: $failing_seeds_file"
  echo "Execution log saved to: $execution_log_file"
  
  if [[ $failing_seeds_found -gt 0 ]]; then
    echo ""
    echo "Found failing seeds:"
    cat "$failing_seeds_file"
    echo ""
    echo "Use 'bashTestRunner <tests> <ignored> -r <seed>' to reproduce any of these failures"
  fi
  
  return $failing_seeds_found
}