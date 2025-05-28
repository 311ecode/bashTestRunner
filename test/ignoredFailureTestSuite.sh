#!/bin/bash
# Test suite that verifies ignored failing tests don't cause overall failure

# A test that will pass
bashTestRunner_testIgnoredFailureSuitePass() {
  echo "Running a test that will pass"
  return 0
}

# A test that will fail but is ignored
bashTestRunner_testIgnoredFailureSuiteFail() {
  echo "Running a test that will deliberately fail (but is ignored)"
  return 1
}

# Test that verifies the test runner returns success despite ignored failures
bashTestRunner_testVerifyIgnoredFailureStatus() {
  echo "Verifying that ignored failing tests don't cause overall failure"
  
  # Create temporary files to capture output and return code
  local temp_output=$(mktemp)
  local temp_rc=$(mktemp)
  
  # Create test functions for this verification
  local test_functions=(
    "bashTestRunner_testIgnoredFailureSuitePass"
    "bashTestRunner_testIgnoredFailureSuiteFail"
  )
  
  # The failing test is ignored
  local ignored_tests=(
    "bashTestRunner_testIgnoredFailureSuiteFail"
  )
  
  # Run bash test runner, showing output AND capturing return code
  echo "=== Test Runner Output ==="
  bashTestRunner test_functions ignored_tests | tee "$temp_output"
  local return_code=$?
  echo "$return_code" > "$temp_rc"
  echo "=== End Output ==="
  
  # Display the captured return code
  return_code=$(cat "$temp_rc")
  echo "bashTestRunner returned: $return_code"
  
  # Verify the output contains expected information
  if ! grep -q "IGNORED (FAIL): bashTestRunner_testIgnoredFailureSuiteFail" "$temp_output"; then
    echo "ERROR: Output doesn't show the ignored failing test"
    rm -f "$temp_output" "$temp_rc"
    return 1
  fi
  
  # Match the exact output format including the newline before "FINAL STATUS:"
  if ! grep -q $'FINAL STATUS:\nPASS: All' "$temp_output"; then
    echo "ERROR: Output doesn't show final PASS status in correct format"
    rm -f "$temp_output" "$temp_rc"
    return 1
  fi
  
  # Verify the runner returned success (0) despite having an ignored failing test
  if [[ "$return_code" -ne 0 ]]; then
    echo "ERROR: Test runner returned non-zero ($return_code) despite failing test being ignored"
    rm -f "$temp_output" "$temp_rc"
    return 1
  else
    echo "SUCCESS: Test runner correctly returned 0 (success) status"
    rm -f "$temp_output" "$temp_rc"
    return 0
  fi
}

# Main function to run the ignored failure test suite
bashTestRunner_ignoredFailureTestSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C
  
  local test_functions=(
    "bashTestRunner_testVerifyIgnoredFailureStatus"
  )
  
  local ignored_tests=(
    # Nothing is ignored in the main suite
  )
  
  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}
