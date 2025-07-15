#!/usr/bin/env bash
testShuffleWithNumericSeed() {
  echo "Testing shuffle with numeric seed"
  
  # Define test functions for verification
  orderTestA() { echo "Order test A"; return 0; }
  orderTestB() { echo "Order test B"; return 0; }
  orderTestC() { echo "Order test C"; return 0; }
  
  local test_functions=("orderTestA" "orderTestB" "orderTestC")
  local ignored_tests=()
  
  # Save current environment
  local saved_seed="${BASH_TEST_RUNNER_SEED:-}"
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  
  # Set seed and clear environment
  export BASH_TEST_RUNNER_SEED="42"
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  
  # Create temp file for output capture
  local temp_output=$(mktemp)
  
  # Run test with seed
  (
    bashTestRunner test_functions ignored_tests
  ) > "$temp_output" 2>&1
  local result=$?
  
  # Restore environment
  if [[ -n "$saved_seed" ]]; then
    export BASH_TEST_RUNNER_SEED="$saved_seed"
  else
    unset BASH_TEST_RUNNER_SEED
  fi
  if [[ -n "$saved_session" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session"; fi
  if [[ -n "$saved_nested" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"; fi
  
  # Read output
  local output=$(cat "$temp_output")
  rm -f "$temp_output"
  
  # Verify shuffling message appears
  if ! echo "$output" | grep -q "Shuffling tests with seed: 42"; then
    echo "ERROR: Missing shuffle notification"
    return 1
  fi
  
  # Verify execution order is logged
  if ! echo "$output" | grep -q "Test execution order:"; then
    echo "ERROR: Missing test execution order"
    return 1
  fi
  
  echo "Numeric seed shuffle test passed"
  return 0
}