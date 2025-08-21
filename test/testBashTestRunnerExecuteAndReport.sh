#!/usr/bin/env bash
# Test script to demonstrate proper usage of bashTestRunner-executeAndReport

# Define some test functions
testPass() {
  echo "This test passes"
  return 0
}

testFail() {
  echo "This test fails"
  return 1
}

testIgnoredFail() {
  echo "This test fails but is ignored"
  return 1
}

# Main test function
testExecuteAndReportFunction() {
  echo "Testing bashTestRunner-executeAndReport function directly"

  # Define test arrays
  local test_functions=("testPass" "testFail" "testIgnoredFail")
  local ignored_tests=("testIgnoredFail")

  # Generate unique run ID
  local run_id=$(date +%s%N | sha256sum | head -c 8)
  local test_pwd="$(pwd)"

  echo "Calling bashTestRunner-executeAndReport with:"
  echo "  test_functions: ${test_functions[*]}"
  echo "  ignored_tests: ${ignored_tests[*]}"
  echo "  run_id: $run_id"
  echo "  test_pwd: $test_pwd"
  echo ""

  # Call the function properly
  bashTestRunner-executeAndReport test_functions ignored_tests "$run_id" "$test_pwd"
  local result=$?

  echo ""
  echo "Function returned: $result"
  return $result
}

# Run the test if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  testExecuteAndReportFunction
fi
