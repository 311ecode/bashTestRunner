#!/usr/bin/env bash
testSeedHuntingWithOrderDependentTests() {
  echo "Testing seed hunting with deliberately order-dependent tests"
  
  # Create tests that depend on execution order
  orderTestFirst() {
    if [[ -f "/tmp/order-test-marker" ]]; then
      echo "ERROR: First test found marker from previous run"
      return 1
    fi
    echo "first_executed" > "/tmp/order-test-marker"
    echo "First test completed"
    return 0
  }
  
  orderTestSecond() {
    if [[ ! -f "/tmp/order-test-marker" ]]; then
      echo "ERROR: Second test missing marker from first test"
      return 1
    fi
    if [[ "$(cat /tmp/order-test-marker)" != "first_executed" ]]; then
      echo "ERROR: Second test found unexpected marker content"
      return 1
    fi
    echo "second_executed" >> "/tmp/order-test-marker"
    echo "Second test completed"
    return 0
  }
  
  orderTestThird() {
    if [[ ! -f "/tmp/order-test-marker" ]]; then
      echo "ERROR: Third test missing marker file"
      return 1
    fi
    local line_count=$(wc -l < "/tmp/order-test-marker")
    if [[ $line_count -ne 2 ]]; then
      echo "ERROR: Third test found unexpected marker state (lines: $line_count)"
      return 1
    fi
    rm -f "/tmp/order-test-marker"
    echo "Third test completed and cleaned up"
    return 0
  }
  
  cleanup() {
    rm -f "/tmp/order-test-marker"
  }
  
  # Clean up before test
  cleanup
  
  local test_functions=("orderTestFirst" "orderTestSecond" "orderTestThird")
  local ignored_tests=()
  
  # Save current environment
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  local saved_seed="${BASH_TEST_RUNNER_SEED:-}"
  
  # Clear environment
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  unset BASH_TEST_RUNNER_SEED
  
  # Create temp files for results
  local temp_failing_seeds=$(mktemp)
  local temp_execution_log=$(mktemp)
  
  # Run seed hunting with limited attempts to find order-dependent failures
  local hunt_result
  bashTestRunner-findFailingSeeds test_functions ignored_tests 20 "$temp_failing_seeds" "$temp_execution_log" > /dev/null 2>&1
  hunt_result=$?
  
  # Restore environment
  if [[ -n "$saved_session" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session"; fi
  if [[ -n "$saved_nested" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"; fi
  if [[ -n "$saved_seed" ]]; then export BASH_TEST_RUNNER_SEED="$saved_seed"; fi
  
  # The hunt should find some failing seeds since our tests are order-dependent
  local failing_seed_count=$(wc -l < "$temp_failing_seeds" 2>/dev/null || echo 0)
  local execution_entries=$(grep -c " | " "$temp_execution_log" || echo 0)
  
  echo "Order-dependent seed hunting completed"
  echo "Total executions: $execution_entries"
  echo "Failing seeds discovered: $failing_seed_count"
  
  # Verify we actually ran tests
  if [[ $execution_entries -eq 0 ]]; then
    echo "ERROR: No test executions were logged"
    cleanup
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  # Verify entries have proper format and valid counters
  local has_counters=false
  local has_failing_names=false
  
  while IFS='|' read -r ts seed status failed passed failing_paths; do
    # Skip header lines
    if [[ "$ts" =~ ^#.*$ ]]; then
      continue
    fi
    
    # Clean up fields
    failed=$(echo "$failed" | tr -d ' ')
    passed=$(echo "$passed" | tr -d ' ')
    status=$(echo "$status" | tr -d ' ')
    failing_paths=$(echo "$failing_paths" | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    # Check for valid numeric counters
    if [[ "$failed" =~ ^[0-9]+$ && "$passed" =~ ^[0-9]+$ ]]; then
      if [[ "$failed" -gt 0 ]] || [[ "$passed" -gt 0 ]]; then
        has_counters=true
      fi
    fi
    
    # Check for failing test names/paths when status is FAIL
    if [[ "$status" == "FAIL" && -n "$failing_paths" ]]; then
      has_failing_names=true
      echo "Found failing paths: $failing_paths"
      
      # Check if paths contain our test names (either simple or hierarchical)
      if [[ "$failing_paths" == *"orderTest"* ]]; then
        echo "  Contains expected test pattern: orderTest*"
      fi
    fi
  done < "$temp_execution_log"
  
  if ! $has_counters; then
    echo "ERROR: No log entries have valid non-zero counters"
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Execution log content:" >&2
      cat "$temp_execution_log" >&2
    fi
    cleanup
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  # If we have failing seeds, we should have failing test names/paths
  if [[ $failing_seed_count -gt 0 ]] && ! $has_failing_names; then
    echo "ERROR: Failing runs found but missing failing test names in log"
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Execution log content:" >&2
      cat "$temp_execution_log" >&2
    fi
    cleanup
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  echo "SUCCESS: Seed hunting completed with valid format and counters"
  if [[ $has_failing_names ]]; then
    echo "SUCCESS: Found failing test names/paths in failure entries"
  fi
  
  # Test reproducing one of the failing seeds if we found any
  if [[ $failing_seed_count -gt 0 ]]; then
    local first_failing_seed=$(head -1 "$temp_failing_seeds")
    echo "Testing reproduction of failing seed: $first_failing_seed"
    
    local temp_repro=$(mktemp)
    bashTestRunner-reproduceBug test_functions ignored_tests "$first_failing_seed" "$temp_repro" > /dev/null 2>&1
    
    if [[ ! -f "$temp_repro" ]] || ! grep -q "BUG REPRODUCTION REPORT" "$temp_repro"; then
      echo "ERROR: Failed to reproduce bug with discovered seed"
      cleanup
      rm -f "$temp_failing_seeds" "$temp_execution_log" "$temp_repro"
      return 1
    fi
    
    rm -f "$temp_repro"
    echo "Successfully reproduced bug with discovered failing seed"
  fi
  
  # Clean up
  cleanup
  rm -f "$temp_failing_seeds" "$temp_execution_log"
  
  return 0
}