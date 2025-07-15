#!/usr/bin/env bash
testReproduceBugWithKnownSeed() {
  echo "Testing bug reproduction with a known problematic seed"
  
  # Create test functions where order matters
  statefulTestSetup() {
    echo "Setting up test state"
    echo "setup_done" > "/tmp/test-repro-state"
    return 0
  }
  
  statefulTestCheck() {
    if [[ -f "/tmp/test-repro-state" && "$(cat /tmp/test-repro-state)" == "setup_done" ]]; then
      echo "State check passed"
      return 0
    else
      echo "State check failed - no setup found"
      return 1
    fi
  }
  
  cleanup() {
    rm -f "/tmp/test-repro-state"
  }
  
  # Clean up before test
  cleanup
  
  local test_functions=("statefulTestCheck" "statefulTestSetup")  # Intentionally wrong order
  local ignored_tests=()
  
  # Save current environment
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  local saved_seed="${BASH_TEST_RUNNER_SEED:-}"
  
  # Clear environment
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  unset BASH_TEST_RUNNER_SEED
  
  # Create temp file for reproduction output
  local temp_output=$(mktemp)
  
  # Test reproduction with a seed that should cause this order (we'll use "original" to mean no shuffle)
  local result
  bashTestRunner-reproduceBug test_functions ignored_tests "no-shuffle" "$temp_output" > /dev/null 2>&1
  result=$?
  
  # Restore environment
  if [[ -n "$saved_session" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session"; fi
  if [[ -n "$saved_nested" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"; fi
  if [[ -n "$saved_seed" ]]; then export BASH_TEST_RUNNER_SEED="$saved_seed"; fi
  
  # Check if reproduction file was created
  if [[ ! -f "$temp_output" ]]; then
    echo "ERROR: Reproduction output file was not created"
    cleanup
    return 1
  fi
  
  # Check if the reproduction file contains expected content
  if ! grep -q "BUG REPRODUCTION REPORT" "$temp_output"; then
    echo "ERROR: Reproduction file missing expected header"
    cleanup
    rm -f "$temp_output"
    return 1
  fi
  
  if ! grep -q "Seed: no-shuffle" "$temp_output"; then
    echo "ERROR: Reproduction file missing seed information"
    cleanup
    rm -f "$temp_output"
    return 1
  fi
  
  # Verify counters in reproduction output
  if ! grep -q "Failed: [1-9]" "$temp_output"; then
    echo "ERROR: Reproduction output has zero failed count"
    cleanup
    rm -f "$temp_output"
    return 1
  fi
  
  echo "Bug reproduction test completed successfully"
  echo "Reproduction file created with expected content"
  
  # Clean up
  cleanup
  rm -f "$temp_output"
  
  return 0
}