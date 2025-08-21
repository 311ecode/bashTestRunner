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
  local saved_path="${BASH_TEST_RUNNER_TEST_PATH:-}"

  # Ensure no seed is set
  unset BASH_TEST_RUNNER_SEED
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  unset BASH_TEST_RUNNER_TEST_PATH

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
  if [[ -n "$saved_path" ]]; then export BASH_TEST_RUNNER_TEST_PATH="$saved_path"; fi

  local output=$(cat "$temp_output")
  rm -f "$temp_output"

  # Verify no shuffle message appears
  if echo "$output" | grep -q "Shuffling tests with seed:"; then
    echo "ERROR: Should not shuffle without seed"
    return 1
  fi

  # Debug: Show all "Running test:" lines to understand the format
  echo "DEBUG: All 'Running test:' lines found:"
  echo "$output" | grep "Running test:" | head -10

  # Extract test execution order - try multiple patterns to see what works
  local test_order=""
  local seen_tests=()

  # Pattern 1: Try hierarchical format
  while IFS= read -r line; do
    if [[ "$line" =~ ^Running\ test:\ testNoShuffleWithoutSeed-\>(noShuffleTest[ABC])$ ]]; then
      local test_name="${BASH_REMATCH[1]}"
      echo "DEBUG: Matched hierarchical pattern: $test_name"
      # Only add if we haven't seen this test yet
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

  # If that didn't work, try simple format
  if [[ -z "$test_order" ]]; then
    echo "DEBUG: Hierarchical pattern didn't match, trying simple pattern"
    while IFS= read -r line; do
      if [[ "$line" =~ ^Running\ test:\ (noShuffleTest[ABC])$ ]]; then
        local test_name="${BASH_REMATCH[1]}"
        echo "DEBUG: Matched simple pattern: $test_name"
        # Only add if we haven't seen this test yet
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
  fi

  # If still no match, show what we're actually seeing
  if [[ -z "$test_order" ]]; then
    echo "DEBUG: No patterns matched. Sample lines:"
    echo "$output" | grep "Running test:" | head -5
    echo "DEBUG: Full output:"
    echo "$output"
  fi

  test_order=${test_order% }  # Remove trailing space

  echo "DEBUG: Extracted test order: '$test_order'"
  echo "DEBUG: Expected: 'noShuffleTestA noShuffleTestB noShuffleTestC'"

  if [[ "$test_order" != "noShuffleTestA noShuffleTestB noShuffleTestC" ]]; then
    echo "ERROR: Tests not in original order: $test_order"
    echo "Expected: noShuffleTestA noShuffleTestB noShuffleTestC"
    return 1
  fi

  echo "No shuffle test passed - order preserved: $test_order"
  return 0
}
