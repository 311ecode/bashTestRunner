#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.

bashTestRunner-reproduceBug() {
  local test_functions_ref_name=$1
  local ignored_tests_ref_name=$2
  local failing_seed=$3
  local output_file=${4:-"./bug-reproduction-${failing_seed}.log"}
  
  echo "Reproducing bug with seed: $failing_seed"
  echo "Output will be saved to: $output_file"
  echo ""
  
  # Set the failing seed
  export BASH_TEST_RUNNER_SEED="$failing_seed"
  
  # Save current environment
  local temp_session="${BASH_TEST_RUNNER_SESSION:-}"
  local temp_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  
  # Clear environment for clean reproduction
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  
  # Run with the failing seed and capture everything - NO SUBSHELL
  local test_result
  {
    echo "=== BUG REPRODUCTION REPORT ==="
    echo "Timestamp: $(date)"
    echo "Seed: $failing_seed"
    echo "Test functions: ${test_functions_ref_name}"
    echo "Ignored tests: ${ignored_tests_ref_name}"
    echo ""
    echo "=== TEST EXECUTION ==="
    bashTestRunner "$test_functions_ref_name" "$ignored_tests_ref_name"
  } > "$output_file" 2>&1
  test_result=$?
  
  # Restore environment
  if [[ -n "$temp_session" ]]; then
    export BASH_TEST_RUNNER_SESSION="$temp_session"
  fi
  if [[ -n "$temp_nested" ]]; then
    export BASH_TEST_RUNNER_LOG_NESTED="$temp_nested"
  fi
  
  # Unset the seed
  unset BASH_TEST_RUNNER_SEED
  
  echo "Bug reproduction complete!"
  echo "Exit code: $test_result"
  echo "Full output saved to: $output_file"
  
  # Show a summary of what failed
  if [[ $test_result -ne 0 ]]; then
    echo ""
    echo "=== FAILURE SUMMARY ==="
    grep "FAIL:" "$output_file" | head -5
    if [[ $(grep -c "FAIL:" "$output_file") -gt 5 ]]; then
      echo "... and $(($(grep -c "FAIL:" "$output_file") - 5)) more failures"
    fi
  fi
  
  return $test_result
}