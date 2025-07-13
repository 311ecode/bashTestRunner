#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Example test suite using bashTestRunner

testExample1() {
  # Your test code here
  return 0
}

testExample2() {
  # Your test code here
  return 1
}

exampleTestSuite() {
  local test_functions=(
    "testExample1"
    "testExample2"
  )
  
  local ignored_tests=(
    "testExample2"
  )
  
  bashTestRunner test_functions ignored_tests
}