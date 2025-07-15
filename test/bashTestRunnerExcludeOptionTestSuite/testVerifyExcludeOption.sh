#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
testVerifyExcludeOption() {
  echo "Verifying --exclude option functionality with multiple scenarios"
  
  # Define local test functions for verification
  local_test_pass() {
    echo "Local passing test"
    return 0
  }
  
  local_test_fail() {
    echo "Local failing test"
    return 1
  }
  
  # Common setup: test functions array
  local test_funcs=("local_test_pass" "local_test_fail")
  
  # Subtest 1: No exclude, no ignored - expect failure due to local_test_fail
  echo "Subtest 1: No exclude, expect overall failure"
  local ignored1=()
  local temp_output1=$(mktemp)
  local saved_session1="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested1="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  (
    bashTestRunner test_funcs ignored1
  ) > "$temp_output1" 2>&1
  local result1=$?
  if [[ -n "$saved_session1" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session1"; fi
  if [[ -n "$saved_nested1" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested1"; fi
  local output1=$(cat "$temp_output1")
  rm -f "$temp_output1"
  if [[ $result1 -ne 1 ]] || ! echo "$output1" | grep -q "FAIL: local_test_fail" || ! echo "$output1" | grep -A1 "FINAL STATUS:" | grep -q "FAIL:"; then
    echo "ERROR: Subtest 1 failed - unexpected result or output"
    echo "$output1"
    return 1
  fi
  echo "Subtest 1 passed"
  
  # Subtest 2: Exclude the failing test - expect success, ignored fail
  echo "Subtest 2: Exclude failing test, expect overall success"
  local ignored2=()
  local temp_output2=$(mktemp)
  local saved_session2="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested2="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  (
    bashTestRunner test_funcs ignored2 -x "local_test_fail"
  ) > "$temp_output2" 2>&1
  local result2=$?
  if [[ -n "$saved_session2" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session2"; fi
  if [[ -n "$saved_nested2" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested2"; fi
  local output2=$(cat "$temp_output2")
  rm -f "$temp_output2"
  if [[ $result2 -ne 0 ]] || ! echo "$output2" | grep -q "IGNORED (FAIL): local_test_fail" || ! echo "$output2" | grep -q "PASS: local_test_pass" || ! echo "$output2" | grep -A1 "FINAL STATUS:" | grep -q "PASS:"; then
    echo "ERROR: Subtest 2 failed - unexpected result or output"
    echo "$output2"
    return 1
  fi
  echo "Subtest 2 passed"
  
  # Subtest 3: Exclude the passing test - expect failure due to local_test_fail
  echo "Subtest 3: Exclude passing test, expect overall failure"
  local ignored3=()
  local temp_output3=$(mktemp)
  local saved_session3="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested3="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  (
    bashTestRunner test_funcs ignored3 -x "local_test_pass"
  ) > "$temp_output3" 2>&1
  local result3=$?
  if [[ -n "$saved_session3" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session3"; fi
  if [[ -n "$saved_nested3" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested3"; fi
  local output3=$(cat "$temp_output3")
  rm -f "$temp_output3"
  if [[ $result3 -ne 1 ]] || ! echo "$output3" | grep -q "IGNORED (PASS): local_test_pass" || ! echo "$output3" | grep -q "FAIL: local_test_fail" || ! echo "$output3" | grep -A1 "FINAL STATUS:" | grep -q "FAIL:"; then
    echo "ERROR: Subtest 3 failed - unexpected result or output"
    echo "$output3"
    return 1
  fi
  echo "Subtest 3 passed"
  
  # Subtest 4: Pre-ignored failing, exclude passing - expect success (both ignored)
  echo "Subtest 4: Pre-ignored failing, exclude passing, expect success"
  local ignored4=("local_test_fail")
  local temp_output4=$(mktemp)
  local saved_session4="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested4="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  (
    bashTestRunner test_funcs ignored4 -x "local_test_pass"
  ) > "$temp_output4" 2>&1
  local result4=$?
  if [[ -n "$saved_session4" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session4"; fi
  if [[ -n "$saved_nested4" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested4"; fi
  local output4=$(cat "$temp_output4")
  rm -f "$temp_output4"
  if [[ $result4 -ne 0 ]] || ! echo "$output4" | grep -q "IGNORED (FAIL): local_test_fail" || ! echo "$output4" | grep -q "IGNORED (PASS): local_test_pass" || ! echo "$output4" | grep -A1 "FINAL STATUS:" | grep -q "PASS:"; then
    echo "ERROR: Subtest 4 failed - unexpected result or output"
    echo "$output4"
    return 1
  fi
  echo "Subtest 4 passed"
  
  # Subtest 5: Exclude non-existing test - expect no error, same as no exclude
  echo "Subtest 5: Exclude non-existing test, expect no error and overall failure"
  local ignored5=()
  local temp_output5=$(mktemp)
  local saved_session5="${BASH_TEST_RUNNER_SESSION:-}"
  local saved_nested5="${BASH_TEST_RUNNER_LOG_NESTED:-}"
  unset BASH_TEST_RUNNER_SESSION
  unset BASH_TEST_RUNNER_LOG_NESTED
  (
    bashTestRunner test_funcs ignored5 -x "non_existing_test"
  ) > "$temp_output5" 2>&1
  local result5=$?
  if [[ -n "$saved_session5" ]]; then export BASH_TEST_RUNNER_SESSION="$saved_session5"; fi
  if [[ -n "$saved_nested5" ]]; then export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested5"; fi
  local output5=$(cat "$temp_output5")
  rm -f "$temp_output5"
  if [[ $result5 -ne 1 ]] || ! echo "$output5" | grep -q "FAIL: local_test_fail" || ! echo "$output5" | grep -q "PASS: local_test_pass" || ! echo "$output5" | grep -A1 "FINAL STATUS:" | grep -q "FAIL:"; then
    echo "ERROR: Subtest 5 failed - unexpected result or output"
    echo "$output5"
    return 1
  fi
  echo "Subtest 5 passed"
  
  echo "All --exclude subtests passed successfully"
  return 0
}