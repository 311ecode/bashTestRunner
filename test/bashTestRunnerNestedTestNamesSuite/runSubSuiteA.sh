#!/usr/bin/env bash
runSubSuiteA() {
  local test_functions=(
    "nested_innerAPass"
    "nested_innerAFail"
  )
  
  local ignored_tests=(
    "nested_innerAFail"
  )
  
  bashTestRunner test_functions ignored_tests
  return $?
}