#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Test suite to verify the test shuffling functionality

# Main function to run the shuffle test suite
bashTestRunnerShuffleTestSuite() {
  # Fix for localization issue with decimal points
  export LC_NUMERIC=C
  
  local test_functions=(
    "testShuffleWithNumericSeed"
    "testShuffleWithStringSeed"
    "testShuffleConsistency"
    "testNoShuffleWithoutSeed"
    "testShuffleDifferentSeeds"
    "testShuffleOrderCaptureA"
    "testShuffleOrderCaptureB"
    "testShuffleOrderCaptureC"
  )
  
  local ignored_tests=()
  
  # Run the test suite
  bashTestRunner test_functions ignored_tests
  return $?
}