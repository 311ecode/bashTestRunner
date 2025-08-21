#!/usr/bin/env bash

testDeepNestingPathExtraction() {
  echo "Testing hierarchical path extraction with deep nesting (4+ levels)"

  # Level 1
  outerSuite() {
    echo "Outer suite calling middle suite"
    local test_functions=("middleSuite")
    local ignored_tests=()
    bashTestRunner test_functions ignored_tests
    return $?
  }

  # Level 2
  middleSuite() {
    echo "Middle suite calling inner suite"
    local test_functions=("innerSuite")
    local ignored_tests=()
    bashTestRunner test_functions ignored_tests
    return $?
  }

  # Level 3
  innerSuite() {
    echo "Inner suite calling deep test"
    local test_functions=("deepFailingTest")
    local ignored_tests=()
    bashTestRunner test_functions ignored_tests
    return $?
  }

  # Level 4 - the actual failing test
  deepFailingTest() {
    echo "Deep failing test at level 4"
    return 1
  }

  local test_functions=("outerSuite")
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

  # Run seed hunting with limited attempts - should find the deep hierarchical failure
  bashTestRunner-findFailingSeeds test_functions ignored_tests 2 "$temp_failing_seeds" "$temp_execution_log" > /dev/null 2>&1
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

  # Check for the complete 4-level hierarchical path
  local expected_path="outerSuite->middleSuite->innerSuite->deepFailingTest"
  local has_deep_hierarchical_path=false
  local found_complete_path=""

  while IFS='|' read -r timestamp seed status failed passed paths; do
    # Clean up whitespace and newlines
    status=$(echo "$status" | tr -d ' \n\r')
    paths=$(echo "$paths" | sed 's/^[ \t\n\r]*//;s/[ \t\n\r]*$//')

    if [[ "$status" == "FAIL" ]]; then
      # The paths field contains comma-separated failure paths
      # We want to find the longest/most complete one
      IFS=',' read -r -a path_array <<< "$paths"

      for single_path in "${path_array[@]}"; do
        single_path=$(echo "$single_path" | sed 's/^[ \t]*//;s/[ \t]*$//')

        if [[ "$single_path" == "$expected_path" ]]; then
          has_deep_hierarchical_path=true
          found_complete_path="$single_path"
          echo "SUCCESS: Found expected 4-level hierarchical path: $single_path"
          break 2
        fi
      done
    fi
  done < <(grep " | FAIL | " "$temp_execution_log")

  if ! $has_deep_hierarchical_path; then
    echo "ERROR: Expected 4-level hierarchical path '$expected_path' not found"
    echo "Full execution log:"
    cat "$temp_execution_log"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi

  # Verify the found path has all expected components in the correct order
  local components=("outerSuite" "middleSuite" "innerSuite" "deepFailingTest")

  # Check that all components appear in the correct order in the complete path
  # Use a simpler approach: check that each component appears before the next one
  local search_from=0
  for i in "${!components[@]}"; do
    local component="${components[$i]}"

    # Find the position of this component starting from where we left off
    local remaining_path="${found_complete_path:$search_from}"
    local relative_pos=$(echo "$remaining_path" | grep -b -o "$component" | head -1 | cut -d: -f1)

    if [[ -z "$relative_pos" ]]; then
      echo "ERROR: Component '$component' not found in remaining path: $remaining_path"
      rm -f "$temp_failing_seeds" "$temp_execution_log"
      return 1
    fi

    # Update search position for next component
    search_from=$((search_from + relative_pos + ${#component}))

    echo "  Component '$component' found at position $((search_from - ${#component}))"
  done

  echo "SUCCESS: All 4 levels found in correct order: $found_complete_path"

  # Verify we have exactly 3 arrow separators for 4 levels
  local arrow_count=$(echo "$found_complete_path" | grep -o -- '->' | wc -l)
  if [[ $arrow_count -ne 3 ]]; then
    echo "ERROR: Expected 3 arrows for 4 levels, found $arrow_count in: $found_complete_path"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi

  echo "SUCCESS: Correct number of hierarchical separators (3 arrows for 4 levels)"

  # Clean up
  rm -f "$temp_failing_seeds" "$temp_execution_log"

  return 0
}
