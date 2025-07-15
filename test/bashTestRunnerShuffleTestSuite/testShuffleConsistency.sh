#!/usr/bin/env bash
testShuffleConsistency() {
  echo "Testing shuffle consistency with same seed"
  
  # Define test functions
  consistencyTestA() { echo "Consistency A"; return 0; }
  consistencyTestB() { echo "Consistency B"; return 0; }
  consistencyTestC() { echo "Consistency C"; return 0; }
  consistencyTestD() { echo "Consistency D"; return 0; }
  
  local test_functions=("consistencyTestA" "consistencyTestB" "consistencyTestC" "consistencyTestD")
  local ignored_tests=()
  
  # Save environment
  local saved_seed="${BASH_TEST_RUNNER_SEED:-}"
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  
  # Run first test with seed "123"
  export BASH_TEST_RUNNER_SEED="123"
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  
  local temp_output1=$(mktemp)
  (
    bashTestRunner test_functions ignored_tests
  ) > "$temp_output1" 2>&1
  
  local order1=$(grep "Test execution order:" "$temp_output1" | sed 's/Test execution order: //')
  
  # Run second test with same seed "123"
  export BASH_TEST_RUNNER_SEED="123"
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  
  local temp_output2=$(mktemp)
  (
    bashTestRunner test_functions ignored_tests
  ) > "$temp_output2" 2>&1
  
  local order2=$(grep "Test execution order:" "$temp_output2" | sed 's/Test execution order: //')
  
  # Restore environment
  if [[ -n "$saved_seed" ]]; then
    export BASH_TEST_RUNNER_SEED="$saved_seed"
  else
    unset BASH_TEST_RUNNER_SEED
  fi
  if [[ -n "$saved_session" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session"; fi
  if [[ -n "$saved_nested" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"; fi
  
  # Clean up
  rm -f "$temp_output1" "$temp_output2"
  
  # Verify orders are identical
  if [[ "$order1" != "$order2" ]]; then
    echo "ERROR: Orders should be identical with same seed"
    echo "First run:  $order1"
    echo "Second run: $order2"
    return 1
  fi
  
  echo "Shuffle consistency test passed: $order1"
  return 0
}