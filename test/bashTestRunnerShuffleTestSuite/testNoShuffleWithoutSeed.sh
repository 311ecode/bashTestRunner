#!/usr/bin/env bash
testNoShuffleWithoutSeed() {
  echo "Testing no shuffle when seed is not set"
  
  # Define test functions
  noShuffleTestA() { echo "No shuffle A"; return 0; }
  noShuffleTestB() { echo "No shuffle B"; return 0; }
  noShuffleTestC() { echo "No shuffle C"; return 0; }
  
  local test_functions=("noShuffleTestA" "noShuffleTestB" "noShuffleTestC")
  local ignored_tests=()
  
  # Save environment
  local saved_seed="${BASH_TEST_RUNNER_SEED:-}"
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  
  # Ensure no seed is set
  unset BASH_TEST_RUNNER_SEED
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  
  local temp_output=$(mktemp)
  (
    bashTestRunner test_functions ignored_tests
  ) > "$temp_output" 2>&1
  
  # Restore environment
  if [[ -n "$saved_seed" ]]; then
    export BASH_TEST_RUNNER_SEED="$saved_seed"
  fi
  if [[ -n "$saved_session" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session"; fi
  if [[ -n "$saved_nested" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"; fi
  
  local output=$(cat "$temp_output")
  rm -f "$temp_output"
  
  # Debug output if needed
  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: Captured output:" >&2
    echo "$output" >&2
  fi
  
  # Verify no shuffle message appears
  if echo "$output" | grep -q "Shuffling tests with seed:"; then
    echo "ERROR: Should not shuffle without seed"
    return 1
  fi
  
  # Extract test execution order more carefully - look for unique "Running test:" lines
  local test_order=""
  local seen_tests=()
  
  while IFS= read -r line; do
    if [[ "$line" =~ ^Running\ test:\ (noShuffleTest[ABC])$ ]]; then
      local test_name="${BASH_REMATCH[1]}"
      # Only add if we haven't seen this test yet (avoid duplicates from tail output)
      local already_seen=false
      for seen in "${seen_tests[@]}"; do
        if [[ "$seen" == "$test_name" ]]; then
          already_seen=true
          break
        fi
      done
      
      if ! $already_seen; then
        seen_tests+=("$test_name")
        test_order+="$test_name "
      fi
    fi
  done <<< "$output"
  
  test_order=${test_order% }  # Remove trailing space
  
  if [[ "$test_order" != "noShuffleTestA noShuffleTestB noShuffleTestC" ]]; then
    echo "ERROR: Tests not in original order: $test_order"
    echo "Expected: noShuffleTestA noShuffleTestB noShuffleTestC"
    if [[ -n "$DEBUG" ]]; then
      echo "Full output for debugging:"
      echo "$output"
    fi
    return 1
  fi
  
  echo "No shuffle test passed - order preserved: $test_order"
  return 0
}