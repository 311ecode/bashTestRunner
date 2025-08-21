#!/usr/bin/env bash
bashTestRunnerBasicTestSuiteStringComparison() {
  local str1="hello"
  local str2="hello"

  if [[ "$str1" == "$str2" ]]; then
    sleep 1.5  # Sleep for 1.5 seconds
    return 0
  else
    return 1
  fi
}
