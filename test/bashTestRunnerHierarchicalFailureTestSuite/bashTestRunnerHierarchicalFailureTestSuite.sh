#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Test suite to verify hierarchical failure path reporting

bashTestRunnerHierarchicalFailureTestSuite() {
  export LC_NUMERIC=C

  local test_functions=(
    "testHierarchicalFailureReporting"
  )

  local ignored_tests=()

  bashTestRunner test_functions ignored_tests
  return $?
}
