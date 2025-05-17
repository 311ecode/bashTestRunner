#!/bin/bash
# Test suite to verify that the test runner returns non-zero status on failure

# A test that will pass
bashTestRunner_testFailureStatusPass() {
  echo "Running a test that will pass"
  return 0
}

# A test that will deliberately fail
bashTestRunner_testFailureStatusFail() {
  echo "Running a test that will deliberately fail"
  return 1
}

# Test that verifies the test runner returns the correct exit code
testVerifyReturnStatus() {
  echo "Verifying that the test runner returns non-zero status when tests fail"
  
  # Create a temporary file to capture the return code
  local temp_output=$(mktemp)
  
  # Create test functions for this verification
  local test_functions=(
    "bashTestRunner_testFailureStatusPass"
    "bashTestRunner_testFailureStatusFail"
  )
  
  # No tests are ignored - we want the failure to count
  local ignored_tests=()
  
  # Run bash test runner in a subshell to capture its return code
  (
    bashTestRunner test_functions ignored_tests > /dev/null 2>&1
    echo $? > "$temp_output"
  )
  
  # Read the captured return code
  local return_code=$(cat "$temp_output")
  rm -f "$temp_output"
  
  echo "bashTestRunner returned: $return_code"
  
  # Verify the runner returned a non-zero value due to the failed test
  if [[ "$return_code" -eq 0 ]]; then
    echo "ERROR: Test runner returned 0 (success) despite having a failing test"
    return 1
  else
    echo "SUCCESS: Test runner correctly returned non-zero ($return_code) status"
    return 0
  fi
}

# Main function to run the failure status test suite
failureStatusTestSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C
  
  local test_functions=(
    "testVerifyReturnStatus"
  )
  
  local ignored_tests=(
    # Nothing is ignored
  )
  
  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}