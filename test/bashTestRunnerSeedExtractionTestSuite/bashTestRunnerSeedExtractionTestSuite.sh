#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Test suite to verify correct hierarchical path extraction in seed hunting

bashTestRunnerSeedExtractionTestSuite() {
  export LC_NUMERIC=C
  
  local test_functions=(
    "testHierarchicalPathExtractionBasic"
    "testExecutionLogFormatConsistency"
    "testDeepNestingPathExtraction"
    "testMixedPassFailPathExtraction"
  )
  
  local ignored_tests=()
  
  bashTestRunner test_functions ignored_tests
  return $?
}