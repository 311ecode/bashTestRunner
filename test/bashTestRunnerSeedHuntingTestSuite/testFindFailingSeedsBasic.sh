#!/usr/bin/env bash
testFindFailingSeedsBasic() {
  echo "Testing basic failing seed discovery functionality"
  
  # Create test functions that will fail in certain orders
  orderDependentTestA() {
    if [[ -f "/tmp/test-state-file" ]]; then
      echo "State file exists, failing"
      return 1
    else
      echo "Creating state file"
      touch "/tmp/test-state-file"
      return 0
    fi
  }
  
  orderDependentTestB() {
    echo "Test B always passes"
    return 0
  }
  
  cleanup() {
    rm -f "/tmp/test-state-file"
  }
  
  # Clean up before test
  cleanup
  
  local test_functions=("orderDependentTestA" "orderDependentTestB")
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
  
  # Run seed hunting with limited attempts
  local result
  bashTestRunner-findFailingSeeds test_functions ignored_tests 10 "$temp_failing_seeds" "$temp_execution_log" > /dev/null 2>&1
  result=$?
  
  # Restore environment
  if [[ -n "$saved_session" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session"; fi
  if [[ -n "$saved_nested" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"; fi
  if [[ -n "$saved_seed" ]]; then export BASH_TEST_RUNNER_SEED="$saved_seed"; fi
  
  # Check if files were created
  if [[ ! -f "$temp_failing_seeds" ]] || [[ ! -f "$temp_execution_log" ]]; then
    echo "ERROR: Expected output files were not created"
    cleanup
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  # Check if execution log has the expected format
  if ! grep -q "# Test execution log" "$temp_execution_log"; then
    echo "ERROR: Execution log missing expected header"
    cleanup
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  # Check if we have execution entries (look for pipe-separated format)
  local execution_count=$(grep -c " | " "$temp_execution_log" || true)
  if [[ $execution_count -eq 0 ]]; then
    echo "ERROR: No execution entries found in log"
    cleanup
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  # Verify entries have proper format (6 fields separated by 5 pipes)
  local malformed_count=0
  while IFS= read -r line; do
    # Skip header and empty lines
    if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
      continue
    fi
    
    # Count pipe separators - should be exactly 5
    local pipe_count=$(echo "$line" | tr -cd '|' | wc -c)
    if [[ $pipe_count -ne 5 ]]; then
      ((malformed_count++))
    fi
  done < "$temp_execution_log"
  
  if [[ $malformed_count -gt 0 ]]; then
    echo "ERROR: Found $malformed_count malformed log entries"
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Execution log content:" >&2
      cat "$temp_execution_log" >&2
    fi
    cleanup
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  # Verify counters in at least one entry
  local has_nonzero=false
  while IFS='|' read -r ts seed status failed passed failing; do
    failed=$(echo "$failed" | tr -d ' ')
    passed=$(echo "$passed" | tr -d ' ')
    if [[ "$failed" =~ ^[0-9]+$ && "$passed" =~ ^[0-9]+$ ]]; then
      if [[ "$failed" -gt 0 ]] || [[ "$passed" -gt 0 ]]; then
        has_nonzero=true
        break
      fi
    fi
  done < <(grep " | " "$temp_execution_log")
  
  if ! $has_nonzero; then
    echo "ERROR: All log entries have zero or invalid counters"
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Execution log content:" >&2
      cat "$temp_execution_log" >&2
    fi
    cleanup
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  echo "Seed hunting completed successfully"
  echo "Executions logged: $execution_count"
  echo "Failing seeds found: $(wc -l < "$temp_failing_seeds" 2>/dev/null || echo 0)"
  
  # Clean up
  cleanup
  rm -f "$temp_failing_seeds" "$temp_execution_log"
  
  return 0
}