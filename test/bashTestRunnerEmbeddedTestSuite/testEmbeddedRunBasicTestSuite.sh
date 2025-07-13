#!/usr/bin/env bash
testEmbeddedRunBasicTestSuite() {
  echo "Running the basic test suite as an embedded test"
  
  # Run the test suite and check its return value
  basicTestSuite
  local result=$?
  
  if [[ $result -eq 0 ]]; then
    echo "Basic test suite passed successfully"
    return 0
  else
    echo "Basic test suite failed with exit code $result"
    return 1
  fi
}