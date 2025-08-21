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
  echo "# Format: TIMESTAMP | SEED | STATUS | FAILED_TESTS | PASSED_TESTS | FAILING_TESTS_WITH_PATHS" >> "$execution_log_file"

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
    local temp_path="${BASH_TEST_RUNNER_TEST_PATH:-}"

    # Clear environment for clean run
    unset BASH_TEST_RUNNER_SESSION
    unset BASH_TEST_RUNNER_LOG_NESTED
    unset BASH_TEST_RUNNER_TEST_PATH

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
    if [[ -n "$temp_path" ]]; then
      export BASH_TEST_RUNNER_TEST_PATH="$temp_path"
    fi

    # Parse the results from the most recent session
    local failed_count=0
    local passed_count=0
    local failing_tests_with_paths=""

    # Find the most recent main.log by modification time
    local latest_main_log=$(find /tmp/bashTestRunnerSessions -name "main.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
    if [[ -n "$latest_main_log" ]]; then
      local latest_session_dir=$(dirname "$latest_main_log")

      # Extract counts from the TEST SUMMARY section - look for the last summary
      local summary_start=$(grep -n "^TEST SUMMARY$" "$latest_main_log" | tail -1 | cut -d: -f1)

      if [[ -n "$summary_start" ]]; then
        # Get lines after "TEST SUMMARY" until next ====== line
        local summary_section=$(tail -n +$((summary_start + 2)) "$latest_main_log" | sed '/^======================================$/q' | head -n -1)

        if [[ -n "$summary_section" ]]; then
          # Look for the actual count lines in the summary
          local passed_line=$(echo "$summary_section" | grep "^Passed: " | head -1)
          local failed_line=$(echo "$summary_section" | grep "^Failed: " | head -1)

          if [[ -n "$passed_line" ]]; then
            passed_count=$(echo "$passed_line" | awk '{print $2}')
          fi

          if [[ -n "$failed_line" ]]; then
            failed_count=$(echo "$failed_line" | awk '{print $2}')
          fi
        fi
      fi

      # Fallback: if we didn't get counts from summary, try to count from the log directly
      if [[ "$passed_count" -eq 0 && "$failed_count" -eq 0 ]]; then
        # Count PASS and FAIL lines in the main log (excluding IGNORED)
        local pass_lines=$(grep "^PASS: " "$latest_main_log" | wc -l)
        local fail_lines=$(grep "^FAIL: " "$latest_main_log" | wc -l)

        if [[ $pass_lines -gt 0 || $fail_lines -gt 0 ]]; then
          passed_count=$pass_lines
          failed_count=$fail_lines
        fi
      fi

      # Extract hierarchical failure paths directly from FAIL: lines in main log
      if [[ $test_result -ne 0 ]]; then
        # Look for "FAIL: path" lines, preserving full hierarchical paths
        local fail_lines=$(grep "^FAIL: " "$latest_main_log" | head -5)

        if [[ -n "$fail_lines" ]]; then
          # Extract just the path portion (before " completed in")
          local paths=()
          while IFS= read -r line; do
            if [[ "$line" =~ ^FAIL:\ (.*)\ completed\ in ]]; then
              paths+=("${BASH_REMATCH[1]}")
            fi
          done <<< "$fail_lines"

          # Join paths with comma
          local IFS=','
          failing_tests_with_paths="${paths[*]}"
        fi
      fi
    fi

    # Ensure we have valid numeric values
    [[ "$failed_count" =~ ^[0-9]+$ ]] || failed_count=0
    [[ "$passed_count" =~ ^[0-9]+$ ]] || passed_count=0

    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Latest main log: $latest_main_log" >&2
      echo "DEBUG: Failed count: $failed_count" >&2
      echo "DEBUG: Passed count: $passed_count" >&2
      echo "DEBUG: Failing tests with paths: $failing_tests_with_paths" >&2
    fi

    # Log this execution with enhanced path information
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local status="PASS"
    if [[ $test_result -ne 0 ]]; then
      status="FAIL"
    fi

    # Create a single, properly formatted log line
    printf "%s | %s | %s | %d | %d | %s\n" "$timestamp" "$random_seed" "$status" "$failed_count" "$passed_count" "$failing_tests_with_paths" >> "$execution_log_file"

    # Report result
    echo ""
    echo "RESULT: $status (exit code: $test_result)"
    echo "Failed tests: $failed_count"
    echo "Passed tests: $passed_count"
    if [[ -n "$failing_tests_with_paths" ]]; then
      echo "Failing paths: $failing_tests_with_paths"
    fi

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
    echo ""
    echo "📍 HIERARCHICAL FAILURE PATHS:"
    echo "The execution log now shows full paths to failing tests, making debugging much easier!"
    grep "FAIL" "$execution_log_file" | head -5 | while IFS='|' read -r ts seed status failed passed paths; do
      paths=$(echo "$paths" | sed 's/^[ \t]*//;s/[ \t]*$//')  # trim whitespace
      if [[ -n "$paths" ]]; then
        echo "  Seed $(echo "$seed" | sed 's/^[ \t]*//;s/[ \t]*$//'): $paths"
      fi
    done
  fi

  return $failing_seeds_found
}
