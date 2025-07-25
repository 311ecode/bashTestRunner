#!/usr/bin/env bash

testHierarchicalPathExtractionBasic() {
  echo "Testing that seed hunting correctly extracts hierarchical failure paths"
  
  # Create nested test structure with guaranteed failure
  parentTest() {
    echo "Parent test running child"
    local test_functions=("childTest")
    local ignored_tests=()
    bashTestRunner test_functions ignored_tests
    return $?
  }
  
  childTest() {
    echo "Child test running grandchild"
    local test_functions=("grandchildFailingTest")
    local ignored_tests=()
    bashTestRunner test_functions ignored_tests
    return $?
  }
  
  grandchildFailingTest() {
    echo "Grandchild test - guaranteed to fail"
    return 1
  }
  
  local test_functions=("parentTest")
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
  
  # Run seed hunting with limited attempts - should find the hierarchical failure
  bashTestRunner-findFailingSeeds test_functions ignored_tests 3 "$temp_failing_seeds" "$temp_execution_log" > /dev/null 2>&1
  local hunt_result=$?
  
  # Restore environment
  if [[ -n "$saved_session" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session"; fi
  if [[ -n "$saved_nested" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"; fi
  if [[ -n "$saved_seed" ]]; then export BASH_TEST_RUNNER_SEED="$saved_seed"; fi
  if [[ -n "$saved_path" ]]; then export BASH_TEST_RUNNER_TEST_PATH="$saved_path"; fi
  
  # Verify the execution log was created
  if [[ ! -f "$temp_execution_log" ]]; then
    echo "ERROR: Execution log file was not created"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  # Since our test always fails, we should have FAIL entries
  local fail_count=$(grep -c " | FAIL | " "$temp_execution_log" || echo 0)
  if [[ $fail_count -eq 0 ]]; then
    echo "ERROR: Expected FAIL entries but found none (test should always fail)"
    echo "Execution log content:"
    cat "$temp_execution_log"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  echo "Found $fail_count FAIL entries as expected"
  
  # Check for proper hierarchical paths in the execution log
  local expected_path="parentTest->childTest->grandchildFailingTest"
  local has_hierarchical_path=false
  
  while IFS='|' read -r timestamp seed status failed passed paths; do
    # Clean up whitespace
    status=$(echo "$status" | tr -d ' ')
    paths=$(echo "$paths" | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    if [[ "$status" == "FAIL" && "$paths" == *"$expected_path"* ]]; then
      has_hierarchical_path=true
      echo "SUCCESS: Found expected hierarchical path: $paths"
      break
    fi
  done < <(grep " | FAIL | " "$temp_execution_log")
  
  if ! $has_hierarchical_path; then
    echo "ERROR: Expected hierarchical path '$expected_path' not found in execution log"
    echo "FAIL entries found:"
    grep " | FAIL | " "$temp_execution_log"
    echo ""
    echo "Full execution log:"
    cat "$temp_execution_log"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  # Verify the execution log has proper single-line format (no scattered fields)
  local malformed_lines=0
  while IFS= read -r line; do
    # Skip header and empty lines
    if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
      continue
    fi
    
    # Count pipe separators - should be exactly 5 (6 fields total)
    local pipe_count=$(echo "$line" | tr -cd '|' | wc -c)
    if [[ $pipe_count -ne 5 ]]; then
      ((malformed_lines++))
      echo "MALFORMED LINE (pipes: $pipe_count): $line"
    fi
  done < "$temp_execution_log"
  
  if [[ $malformed_lines -gt 0 ]]; then
    echo "ERROR: Found $malformed_lines malformed lines in execution log"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  echo "All execution log lines are properly formatted"
  
  # Clean up
  rm -f "$temp_failing_seeds" "$temp_execution_log"
  
  return 0
}