#!/usr/bin/env bash
testShuffleWithStringSeed() {
  echo "Testing shuffle with string seed"
  
  # Define test functions for verification
  stringTestA() { echo "String test A"; return 0; }
  stringTestB() { echo "String test B"; return 0; }
  stringTestC() { echo "String test C"; return 0; }
  
  local test_functions=("stringTestA" "stringTestB" "stringTestC")
  local ignored_tests=()
  
  # Save current environment
  local saved_seed="${BASH_TEST_RUNNER_SEED:-}"
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  
  # Set string seed and clear environment
  export BASH_TEST_RUNNER_SEED="hello_world"
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  
  # Create temp file for output capture
  local temp_output=$(mktemp)
  
  # Run test with string seed
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
  if ! echo "$output" | grep -q "Shuffling tests with seed: hello_world"; then
    echo "ERROR: Missing shuffle notification for string seed"
    return 1
  fi
  
  echo "String seed shuffle test passed"
  return 0
}