#!/usr/bin/env bash
testHierarchicalSeedHuntingReporting() {
  echo "Testing hierarchical failure path reporting in seed hunting"
  
  # Create a test that ALWAYS fails (deterministic failure)
  alwaysFailingLevel1() {
    echo "Level 1 test that always fails"
    return 1
  }
  
  # Create a nested suite that contains the failing test
  nestedSuiteWithFailure() {
    echo "Running nested suite with guaranteed failure"
    local test_functions=("alwaysFailingLevel2")
    local ignored_tests=()
    bashTestRunner test_functions ignored_tests
    return $?
  }
  
  alwaysFailingLevel2() {
    echo "Level 2 test that always fails"
    return 1
  }
  
  # Create test suite with GUARANTEED failure
  local test_functions=("alwaysFailingLevel1" "nestedSuiteWithFailure")
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
  
  # Create temp files for results
  local temp_failing_seeds=$(mktemp)
  local temp_execution_log=$(mktemp)
  
  # Run seed hunting with limited attempts - should ALWAYS find failures
  local result
  bashTestRunner-findFailingSeeds test_functions ignored_tests 3 "$temp_failing_seeds" "$temp_execution_log" > /dev/null 2>&1
  result=$?
  
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
  
  # Verify the log has the new hierarchical format header
  if ! grep -q "FAILING_TESTS_WITH_PATHS" "$temp_execution_log"; then
    echo "ERROR: Execution log missing new hierarchical format header"
    echo "Log header content:"
    head -3 "$temp_execution_log"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  # Since our tests ALWAYS fail, we should ALWAYS have FAIL entries
  local fail_count=$(grep -c "FAIL" "$temp_execution_log" || echo 0)
  if [[ $fail_count -eq 0 ]]; then
    echo "ERROR: Expected FAIL entries but found none (tests should always fail)"
    echo "Full log content:"
    cat "$temp_execution_log"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  echo "Found $fail_count FAIL entries as expected"
  
  # Check for hierarchical paths in failure entries
  local has_hierarchical_paths=false
  local sample_hierarchical_entry=""
  
  # Look for any line containing hierarchical paths (with ->)
  while IFS= read -r line; do
    if [[ "$line" == *"->"* ]] && [[ "$line" == *"nestedSuiteWithFailure"* || "$line" == *"alwaysFailingLevel"* ]]; then
      has_hierarchical_paths=true
      sample_hierarchical_entry="$line"
      echo "Found hierarchical path: $line"
      break
    fi
  done < "$temp_execution_log"
  
  if ! $has_hierarchical_paths; then
    echo "ERROR: No hierarchical paths found in failure entries"
    echo "Full log content:"
    cat "$temp_execution_log"
    
    # Show any lines containing our test names for debugging
    echo ""
    echo "Lines containing test names:"
    grep -E "(alwaysFailingLevel|nestedSuiteWithFailure)" "$temp_execution_log" || echo "No lines found with test names"
    
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  # Verify the hierarchical path contains expected test names
  if [[ "$sample_hierarchical_entry" != *"nestedSuiteWithFailure->alwaysFailingLevel2"* ]] && 
     [[ "$sample_hierarchical_entry" != *"alwaysFailingLevel"* ]]; then
    echo "ERROR: Expected hierarchical path containing test names, got: $sample_hierarchical_entry"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  echo "SUCCESS: Hierarchical seed hunting reporting working correctly"
  echo "Sample hierarchical failure path found: $sample_hierarchical_entry"
  
  # Verify we had some failing seeds
  local failing_seed_count=$(wc -l < "$temp_failing_seeds" 2>/dev/null || echo 0)
  if [[ $failing_seed_count -eq 0 ]]; then
    echo "ERROR: Expected some failing seeds but found none"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi
  
  echo "Found $failing_seed_count failing seeds as expected"
  
  # Clean up
  rm -f "$temp_failing_seeds" "$temp_execution_log"
  
  return 0
}