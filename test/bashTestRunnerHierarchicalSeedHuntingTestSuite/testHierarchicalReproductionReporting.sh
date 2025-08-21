#!/usr/bin/env bash
testHierarchicalReproductionReporting() {
  echo "Testing hierarchical failure path reporting in bug reproduction"

  # Create nested test structure
  outerSuite() {
    echo "Running outer suite"
    local test_functions=("innerSuite")
    local ignored_tests=()
    bashTestRunner test_functions ignored_tests
    return $?
  }

  innerSuite() {
    echo "Running inner suite"
    local test_functions=("deepFailingTest")
    local ignored_tests=()
    bashTestRunner test_functions ignored_tests
    return $?
  }

  deepFailingTest() {
    echo "Deep failing test - this will fail"
    return 1
  }

  local test_functions=("outerSuite")
  local ignored_tests=()

  # Save current environment
  local saved_session="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  local saved_seed="${BASH_TEST_RUNNER_SEED:-}"
  local saved_path="${BASH_TEST_RUNNER_TEST_PATH:-}"

  # Clear environment
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  unset BASH_TEST_RUNNER_SEED
  unset BASH_TEST_RUNNER_TEST_PATH

  # Create temp file for reproduction output
  local temp_output=$(mktemp)

  # Test reproduction with a known seed
  local test_seed="hierarchical-test-seed"
  bashTestRunner-reproduceBug test_functions ignored_tests "$test_seed" "$temp_output" > /dev/null 2>&1
  local result=$?

  # Restore environment
  if [[ -n "$saved_session" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session"; fi
  if [[ -n "$saved_nested" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"; fi
  if [[ -n "$saved_seed" ]]; then export BASH_TEST_RUNNER_SEED="$saved_seed"; fi
  if [[ -n "$saved_path" ]]; then export BASH_TEST_RUNNER_TEST_PATH="$saved_path"; fi

  # Check if reproduction file was created
  if [[ ! -f "$temp_output" ]]; then
    echo "ERROR: Reproduction output file was not created"
    return 1
  fi

  # Verify the reproduction contains hierarchical failure paths
  local has_hierarchical_failure=false
  local hierarchical_failure_line=""

  while IFS= read -r line; do
    if [[ "$line" == *"FAIL:"* && "$line" == *"->"* ]]; then
      has_hierarchical_failure=true
      hierarchical_failure_line="$line"
      break
    fi
  done < "$temp_output"

  if ! $has_hierarchical_failure; then
    echo "ERROR: Reproduction output missing hierarchical failure paths"
    echo "Reproduction file content:"
    cat "$temp_output"
    rm -f "$temp_output"
    return 1
  fi

  # Verify the hierarchical path shows the full nesting
  local expected_path="outerSuite->innerSuite->deepFailingTest"
  if [[ "$hierarchical_failure_line" != *"$expected_path"* ]]; then
    echo "ERROR: Expected hierarchical path '$expected_path' not found"
    echo "Found line: $hierarchical_failure_line"
    rm -f "$temp_output"
    return 1
  fi

  echo "SUCCESS: Hierarchical reproduction reporting working correctly"
  echo "Found hierarchical failure path: $expected_path"

  # Verify reproduction file has proper structure
  if ! grep -q "BUG REPRODUCTION REPORT" "$temp_output"; then
    echo "ERROR: Reproduction file missing expected header"
    rm -f "$temp_output"
    return 1
  fi

  if ! grep -q "Seed: $test_seed" "$temp_output"; then
    echo "ERROR: Reproduction file missing seed information"
    rm -f "$temp_output"
    return 1
  fi

  echo "Reproduction file structure verified successfully"

  # Clean up
  rm -f "$temp_output"

  return 0
}
