#!/usr/bin/env bash

testExecutionLogFormatConsistency() {
  echo "Testing that execution log maintains consistent format without scattered fields"

  # Create tests with varying complexity to stress-test the parsing
  simplePassTest() {
    echo "Simple passing test"
    return 0
  }

  simpleFailTest() {
    echo "Simple failing test"
    return 1
  }

  nestedSuiteTest() {
    echo "Nested suite with multiple tests"
    local test_functions=("innerTest1" "innerTest2")
    local ignored_tests=()
    bashTestRunner test_functions ignored_tests
    return $?
  }

  innerTest1() {
    echo "Inner test 1 - pass"
    return 0
  }

  innerTest2() {
    echo "Inner test 2 - fail"
    return 1
  }

  local test_functions=("simplePassTest" "simpleFailTest" "nestedSuiteTest")
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

  # Run seed hunting with multiple attempts to get both PASS and FAIL entries
  bashTestRunner-findFailingSeeds test_functions ignored_tests 5 "$temp_failing_seeds" "$temp_execution_log" > /dev/null 2>&1
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

  echo "Analyzing execution log format consistency..."

  # Check each non-header line for proper format
  local total_entries=0
  local malformed_entries=0
  local pass_entries=0
  local fail_entries=0

  while IFS= read -r line; do
    # Skip header and empty lines
    if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
      continue
    fi

    ((total_entries++))

    # Count pipe separators - should be exactly 5 (6 fields total)
    local pipe_count=$(echo "$line" | tr -cd '|' | wc -c)
    if [[ $pipe_count -ne 5 ]]; then
      ((malformed_entries++))
      echo "MALFORMED ENTRY: $line"
      echo "  Expected 5 pipes, found $pipe_count"
      continue
    fi

    # Parse the line to verify field format
    IFS='|' read -r timestamp seed status failed_count passed_count paths <<< "$line"

    # Trim whitespace
    timestamp=$(echo "$timestamp" | sed 's/^[ \t]*//;s/[ \t]*$//')
    seed=$(echo "$seed" | sed 's/^[ \t]*//;s/[ \t]*$//')
    status=$(echo "$status" | sed 's/^[ \t]*//;s/[ \t]*$//')
    failed_count=$(echo "$failed_count" | sed 's/^[ \t]*//;s/[ \t]*$//')
    passed_count=$(echo "$passed_count" | sed 's/^[ \t]*//;s/[ \t]*$//')
    paths=$(echo "$paths" | sed 's/^[ \t]*//;s/[ \t]*$//')

    # Validate field formats
    local field_errors=0

    # Timestamp should be in YYYY-MM-DD HH:MM:SS format
    if ! [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
      echo "  Invalid timestamp format: '$timestamp'"
      ((field_errors++))
    fi

    # Seed should be non-empty alphanumeric
    if ! [[ "$seed" =~ ^[a-zA-Z0-9]+$ ]]; then
      echo "  Invalid seed format: '$seed'"
      ((field_errors++))
    fi

    # Status should be PASS or FAIL
    if [[ "$status" != "PASS" && "$status" != "FAIL" ]]; then
      echo "  Invalid status: '$status'"
      ((field_errors++))
    fi

    # Counts should be numeric
    if ! [[ "$failed_count" =~ ^[0-9]+$ ]]; then
      echo "  Invalid failed_count: '$failed_count'"
      ((field_errors++))
    fi

    if ! [[ "$passed_count" =~ ^[0-9]+$ ]]; then
      echo "  Invalid passed_count: '$passed_count'"
      ((field_errors++))
    fi

    if [[ $field_errors -gt 0 ]]; then
      ((malformed_entries++))
      echo "  LINE: $line"
    else
      # Count valid entries by status
      if [[ "$status" == "PASS" ]]; then
        ((pass_entries++))
      elif [[ "$status" == "FAIL" ]]; then
        ((fail_entries++))

        # For FAIL entries, verify we have hierarchical paths when expected
        if [[ -n "$paths" && "$paths" == *"->"* ]]; then
          echo "  Valid hierarchical failure path: $paths"
        elif [[ -n "$paths" ]]; then
          echo "  Simple failure path: $paths"
        fi
      fi
    fi

  done < "$temp_execution_log"

  echo ""
  echo "Format analysis results:"
  echo "  Total entries: $total_entries"
  echo "  Malformed entries: $malformed_entries"
  echo "  PASS entries: $pass_entries"
  echo "  FAIL entries: $fail_entries"

  # Verify we have some valid entries
  if [[ $total_entries -eq 0 ]]; then
    echo "ERROR: No execution entries found in log"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi

  # Verify no malformed entries
  if [[ $malformed_entries -gt 0 ]]; then
    echo "ERROR: Found $malformed_entries malformed entries"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi

  # Verify we have both pass and fail entries (given our test mix)
  if [[ $fail_entries -eq 0 ]]; then
    echo "ERROR: Expected some FAIL entries but found none"
    rm -f "$temp_failing_seeds" "$temp_execution_log"
    return 1
  fi

  echo "SUCCESS: All execution log entries are properly formatted"

  # Clean up
  rm -f "$temp_failing_seeds" "$temp_execution_log"

  return 0
}
