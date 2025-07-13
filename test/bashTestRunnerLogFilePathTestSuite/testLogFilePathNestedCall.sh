#!/usr/bin/env bash
testLogFilePathNestedCall() {
  echo "Testing nested bashTestRunner call"
  
  # Create inner test functions
  innerTestPass() {
    echo "Inner test passing"
    return 0
  }
  
  innerTestFail() {
    echo "Inner test failing"
    return 1
  }
  
  local inner_functions=(
    "innerTestPass"
    "innerTestFail"
  )
  
  local inner_ignored=(
    "innerTestFail"
  )
  
  # This should be a nested call and should NOT print log file path
  bashTestRunner inner_functions inner_ignored
  return $?
}