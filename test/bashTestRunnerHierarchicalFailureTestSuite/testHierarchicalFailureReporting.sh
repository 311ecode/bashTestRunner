#!/usr/bin/env bash

testHierarchicalFailureReporting() {
  echo "Testing hierarchical failure path reporting with deeply nested tests"
  
  # Level 3 - deepest failing test
  level3FailingTest() {
    echo "This is the deepest failing test"
    return 1
  }
  
  # Level 2 - calls level 3
  level2CallingLevel3() {
    echo "Level 2 calling level 3"
    local test_functions=("level3FailingTest")
    local ignored_tests=()
    bashTestRunner test_functions ignored_tests
    return $?
  }
  
  # Level 1 - calls level 2
  level1CallingLevel2() {
    echo "Level 1 calling level 2" 
    local test_functions=("level2CallingLevel3")
    local ignored_tests=()
    bashTestRunner test_functions ignored_tests
    return $?
  }
  
  # Top level test that will show full path
  local test_functions=("level1CallingLevel2")
  local ignored_tests=()
  
  # Save current environment
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  local saved_path="${BASH_TEST_RUNNER_TEST_PATH:-}"
  
  # Clear environment for clean test
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  unset BASH_TEST_RUNNER_TEST_PATH
  
  local temp_output=$(mktemp)
  
  # Run the nested failing test
  (
    bashTestRunner test_functions ignored_tests
  ) > "$temp_output" 2>&1
  local result=$?
  
  # Restore environment
  if [[ -n "$saved_session" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session"; fi
  if [[ -n "$saved_nested" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"; fi
  if [[ -n "$saved_path" ]]; then export BASH_TEST_RUNNER_TEST_PATH="$saved_path"; fi
  
  local output=$(cat "$temp_output")
  rm -f "$temp_output"
  
  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: Hierarchical test output:" >&2
    echo "$output" >&2
  fi
  
  # Verify we see the full hierarchical path in failure output
  local expected_path="level1CallingLevel2->level2CallingLevel3->level3FailingTest"
  
  if ! echo "$output" | grep -q "FAIL: $expected_path"; then
    echo "ERROR: Expected to see hierarchical failure path: $expected_path"
    echo "Actual output:"
    echo "$output"
    return 1
  fi
  
  # Verify we see the running test paths too
  if ! echo "$output" | grep -q "Running test: level1CallingLevel2->level2CallingLevel3->level3FailingTest"; then
    echo "ERROR: Expected to see hierarchical running path in output"
    echo "Actual output:"
    echo "$output"
    return 1
  fi
  
  # Verify the test failed overall
  if [[ $result -ne 1 ]]; then
    echo "ERROR: Expected overall test failure (exit 1) but got $result"
    return 1
  fi
  
  echo "Successfully verified hierarchical failure reporting: $expected_path"
  return 0
}