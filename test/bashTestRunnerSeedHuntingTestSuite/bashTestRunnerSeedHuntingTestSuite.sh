#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Test suite to verify the seed hunting functionality

bashTestRunnerSeedHuntingTestSuite() {
  export LC_NUMERIC=C

  local test_functions=(
    "testFindFailingSeedsBasic"
    "testReproduceBugWithKnownSeed"
    "testSeedHuntingWithOrderDependentTests"
  )

  local ignored_tests=(
    testSeedHuntingWithOrderDependentTests
  )

  bashTestRunner test_functions ignored_tests
  return $?
}
