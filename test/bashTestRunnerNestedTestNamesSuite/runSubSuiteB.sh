#!/usr/bin/env bash
runSubSuiteB() {
  local test_functions=(
    "nested_innerBPass"
  )

  local ignored_tests=()

  bashTestRunner test_functions ignored_tests
  return $?
}
