#!/usr/bin/env bash
testEmbeddedRunExampleTestSuite() {
  echo "Running the example test suite as an embedded test"

  # Run the test suite and check its return value
  exampleTestSuite
  local result=$?

  # We expect the example test suite to pass since its failing test is ignored
  if [[ $result -eq 0 ]]; then
    echo "Example test suite passed successfully as expected"
    return 0
  else
    echo "Example test suite failed with exit code $result, but should have passed"
    return 1
  fi
}
