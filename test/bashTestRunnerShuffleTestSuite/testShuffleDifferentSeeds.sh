#!/usr/bin/env bash
testShuffleDifferentSeeds() {
  echo "Testing that different seeds produce different orders"
  
  # Define test functions
  diffSeedTestA() { echo "Diff seed A"; return 0; }
  diffSeedTestB() { echo "Diff seed B"; return 0; }
  diffSeedTestC() { echo "Diff seed C"; return 0; }
  diffSeedTestD() { echo "Diff seed D"; return 0; }
  diffSeedTestE() { echo "Diff seed E"; return 0; }
  
  local test_functions=("diffSeedTestA" "diffSeedTestB" "diffSeedTestC" "diffSeedTestD" "diffSeedTestE")
  local ignored_tests=()
  
  # Save environment
  local saved_seed="${BASH_TEST_RUNNER_SEED:-}"
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  
  # Test with seed "apple"
  export BASH_TEST_RUNNER_SEED="apple"
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  
  local temp_output1=$(mktemp)
  (
    bashTestRunner test_functions ignored_tests
  ) > "$temp_output1" 2>&1
  
  local order1=$(grep "Test execution order:" "$temp_output1" | sed 's/Test execution order: //')
  
  # Test with seed "banana" 
  export BASH_TEST_RUNNER_SEED="banana"
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
  
  # Verify orders are different
  if [[ "$order1" == "$order2" ]]; then
    echo "ERROR: Different seeds should produce different orders"
    echo "Seed 'apple':  $order1"
    echo "Seed 'banana': $order2"
    return 1
  fi
  
  echo "Different seeds test passed:"
  echo "  Seed 'apple':  $order1"
  echo "  Seed 'banana': $order2"
  return 0
}