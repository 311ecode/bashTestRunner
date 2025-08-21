#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Test suite to verify hierarchical failure reporting in seed hunting

bashTestRunnerHierarchicalSeedHuntingTestSuite() {
  export LC_NUMERIC=C

  local test_functions=(
    "testHierarchicalSeedHuntingReporting"
    "testHierarchicalReproductionReporting"
  )

  local ignored_tests=()

  bashTestRunner test_functions ignored_tests
  return $?
}
