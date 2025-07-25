#!/usr/bin/env bash

testMixedPassFailPathExtraction() {
  echo "Testing hierarchical path extraction with mixed pass/fail scenarios"
  
  # Suite that sometimes passes, sometimes fails based on order
  orderDependentSuite() {
    echo "Order-dependent suite with state file checking"
    local test_functions=("checkStateFile" "createStateFile")
    local ignored_tests=()
    bashTestRunner test_functions ignored_tests
    return $?
  }
  
  checkStateFile() {
    if [[ -f "/tmp/seed-extraction-test-state" ]]; then
      echo "State file exists - test passes"
      return 0
    else
      echo "State file missing - test fails"
      return 1
    fi
  }
  
  createStateFile() {
    echo "Creating state file"
    touch "/tmp/seed-extraction-test-state"
    return 0
  }
  
  # Always passing suite for comparison
  alwaysPassingSuite() {
    echo "Always passing suite"
    local test_functions=("simplePassTest")
    local ignored_tests=()
    bashTestRunner test_functions ignored_tests
    return $?
  }
  
  simplePassTest() {
    echo "Simple passing test"
    return 0
  }
  
  # Cleanup function
  cleanup() {
    rm -f "/tmp/seed-extraction-test-state"
  }
  
  # Clean up before test
  cleanup
  
  local test_functions=("orderDependentSuite" "alwaysPassingSuite")
  local ignored_tests=()
  
  # Save current environment
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  local saved_seed="${BASH_TEST_RUNNER_SEED:-}"
  local saved_path="${BASH_TEST_RUNNER_TEST_PATH:-}"
  
  # Clear environment
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  unset BASH_TEST_RUNNER_SEED
  unset BASH_TEST_RUNNER_TEST_PATH
  
  # Create temp files for seed hunting results
  local temp_failing_seeds=$(mktemp)
  local temp_execution_log=$(mktemp)
  
  # Run seed hunting with more attempts to get both pass and fail scenarios
  bashTestRunner-findFailingSeeds test_functions ignored_tests 8 "$temp_failing_seeds" "$temp_execution_log" > /dev/null 2>&1
  local hunt_result=$?
  
  # Restore environment
  if [[ -n "$saved_session" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session"; fi
  if [[ -n "$saved_nested" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"; fi
  if [[ -n "$saved_seed" ]]; then export BASH_TEST_RUNNER_SEED="$saved_seed"; fi
  if [[ -n "$saved_path" ]]; then export BASH_TEST_RUNNER_TEST_PATH="$saved_path"; fi
  
  # Clean up test state
  cleanup
  
  # Verify the execution log was created
  if [[ ! -f "$temp_execution_log" ]]; then
    echo "ERROR: Execution log file was not created"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  # Analyze the results
  local pass_count=$(grep -c " | PASS | " "$temp_execution_log" || echo 0)
  local fail_count=$(grep -c " | FAIL | " "$temp_execution_log" || echo 0)
  
  echo "Analysis results:"
  echo "  PASS entries: $pass_count"
  echo "  FAIL entries: $fail_count"
  
  # We should have some of each due to the order-dependent nature
  if [[ $pass_count -eq 0 && $fail_count -eq 0 ]]; then
    echo "ERROR: No execution entries found"
    echo "Execution log content:"
    cat "$temp_execution_log"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  # Verify PASS entries have empty or minimal paths (no failures to report)
  local pass_with_paths=0
  while IFS='|' read -r timestamp seed status failed passed paths; do
    status=$(echo "$status" | tr -d ' ')
    paths=$(echo "$paths" | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    if [[ "$status" == "PASS" && -n "$paths" ]]; then
      ((pass_with_paths++))
      echo "  PASS entry unexpectedly has paths: $paths"
    fi
  done < <(grep " | PASS | " "$temp_execution_log")
  
  if [[ $pass_with_paths -gt 0 ]]; then
    echo "ERROR: Found $pass_with_paths PASS entries with failure paths (should be empty)"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  echo "SUCCESS: PASS entries correctly have no failure paths"
  
  # Verify FAIL entries have hierarchical paths when there are failures
  local fail_with_hierarchical_paths=0
  local expected_fail_path="orderDependentSuite->checkStateFile"
  
  while IFS='|' read -r timestamp seed status failed passed paths; do
    status=$(echo "$status" | tr -d ' ')
    paths=$(echo "$paths" | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    if [[ "$status" == "FAIL" ]]; then
      if [[ "$paths" == *"$expected_fail_path"* ]]; then
        ((fail_with_hierarchical_paths++))
        echo "  Found expected hierarchical failure path: $paths"
      elif [[ -n "$paths" ]]; then
        echo "  Found other failure path: $paths"
      else
        echo "  FAIL entry missing failure paths"
      fi
    fi
  done < <(grep " | FAIL | " "$temp_execution_log")
  
  # If we have failures, we should have at least some with our expected path
  if [[ $fail_count -gt 0 && $fail_with_hierarchical_paths -eq 0 ]]; then
    echo "ERROR: FAIL entries found but none contain expected hierarchical path '$expected_fail_path'"
    echo "FAIL entries:"
    grep " | FAIL | " "$temp_execution_log"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  if [[ $fail_with_hierarchical_paths -gt 0 ]]; then
    echo "SUCCESS: Found $fail_with_hierarchical_paths FAIL entries with correct hierarchical paths"
  fi
  
  # Verify numeric fields are consistent
  local inconsistent_entries=0
  while IFS='|' read -r timestamp seed status failed passed paths; do
    status=$(echo "$status" | tr -d ' ')
    failed=$(echo "$failed" | tr -d ' ')
    passed=$(echo "$passed" | tr -d ' ')
    paths=$(echo "$paths" | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    # For PASS entries, failed should be 0
    if [[ "$status" == "PASS" && "$failed" != "0" ]]; then
      echo "  PASS entry with non-zero failed count: failed=$failed"
      ((inconsistent_entries++))
    fi
    
    # For FAIL entries, failed should be > 0
    if [[ "$status" == "FAIL" && "$failed" == "0" ]]; then
      echo "  FAIL entry with zero failed count"
      ((inconsistent_entries++))
    fi
    
    # If we have failures, we should have failure paths
    if [[ "$failed" -gt 0 && -z "$paths" ]]; then
      echo "  Entry with failures but no paths: failed=$failed, paths='$paths'"
      ((inconsistent_entries++))
    fi
    
  done < <(grep -E " \| (PASS|FAIL) \| " "$temp_execution_log")
  
  if [[ $inconsistent_entries -gt 0 ]]; then
    echo "ERROR: Found $inconsistent_entries entries with inconsistent data"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  echo "SUCCESS: All entries have consistent numeric fields and paths"
  
  # Clean up
  rm -f "$temp_failing_seeds" "$temp_execution_log"
  
  return 0
}