#!/usr/bin/env bash

bashTestRunner-executeAndReport() {
  # Validate parameters
  if [[ $# -lt 4 ]]; then
    echo "ERROR: bashTestRunner-executeAndReport requires at least 4 parameters" >&2
    echo "Usage: bashTestRunner-executeAndReport <test_functions_array_name> <ignored_tests_array_name> <run_id> <testPwd> [excludes...]" >&2
    return 1
  fi

  local test_functions_ref_name=$1
  local ignored_tests_ref_name=$2
  local run_id=$3
  local testPwd=$4
  shift 4
  local excludes=("$@")

  # Validate that array names are not empty
  if [[ -z "$test_functions_ref_name" ]] || [[ -z "$ignored_tests_ref_name" ]] || [[ -z "$run_id" ]]; then
    echo "ERROR: test_functions_ref_name, ignored_tests_ref_name, and run_id cannot be empty" >&2
    return 1
  fi

  # Validate that the arrays exist
  if ! declare -p "$test_functions_ref_name" &>/dev/null; then
    echo "ERROR: Array '$test_functions_ref_name' does not exist" >&2
    return 1
  fi

  if ! declare -p "$ignored_tests_ref_name" &>/dev/null; then
    echo "ERROR: Array '$ignored_tests_ref_name' does not exist" >&2
    return 1
  fi

  # Get array references for inputs
  local -n test_functions_ref=${test_functions_ref_name}
  local -n ignored_tests_ref=${ignored_tests_ref_name}

  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: bashTestRunner-executeAndReport called with run_id=$run_id" >&2
    echo "DEBUG: test_functions_ref name=${test_functions_ref_name}, ignored_tests_ref name=${ignored_tests_ref_name}" >&2
    echo "DEBUG: Test functions: ${test_functions_ref[*]}" >&2
    echo "DEBUG: Ignored tests: ${ignored_tests_ref[*]}" >&2
    echo "DEBUG: Current BASH_TEST_RUNNER_SESSION: ${BASH_TEST_RUNNER_SESSION:-unset}" >&2
    echo "DEBUG: Current BASH_TEST_RUNNER_LOG_NESTED: ${BASH_TEST_RUNNER_LOG_NESTED:-unset}" >&2
    echo "DEBUG: Current BASH_TEST_RUNNER_TEST_COUNTER: ${BASH_TEST_RUNNER_TEST_COUNTER:-unset}" >&2
    echo "DEBUG: Current BASH_TEST_RUNNER_TEST_PATH: ${BASH_TEST_RUNNER_TEST_PATH:-unset}" >&2
  fi

  # Create uniquely named global arrays
  declare -ga "results_$run_id"
  declare -ga "passing_ignored_tests_$run_id"
  declare -gA "metrics_$run_id"
  declare -gA "suite_durations_$run_id"

  # Determine session directory and nesting level
  local session_dir
  local log_file
  local is_nested=false
  local nested_was_set=0
  local saved_nested
  local session_created_here=false
  local tail_pid
  local counter_initialized_here=false
  local path_initialized_here=false

  if [[ -n "${BASH_TEST_RUNNER_SESSION}" ]]; then
    session_dir="${BASH_TEST_RUNNER_SESSION}"
    is_nested=true
    if [[ -v BASH_TEST_RUNNER_LOG_NESTED ]]; then
      nested_was_set=1
      saved_nested="${BASH_TEST_RUNNER_LOG_NESTED}"
    fi
    export BASH_TEST_RUNNER_LOG_NESTED=1
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Detected nested call, reusing session: $session_dir" >&2
    fi
  else
    local timestamp=$(date +%Y%m%d%H%M%S)
    local session_id=$(date +%s%N | sha256sum | head -c 8)
    session_dir="/tmp/bashTestRunnerSessions/${timestamp}-${session_id}"
    mkdir -p "$session_dir"
    export BASH_TEST_RUNNER_SESSION="${session_dir}"
    session_created_here=true

    if [[ -z "${BASH_TEST_RUNNER_TEST_COUNTER}" ]]; then
      export BASH_TEST_RUNNER_TEST_COUNTER=1
      counter_initialized_here=true
    fi

    if [[ -z "${BASH_TEST_RUNNER_TEST_PATH}" ]]; then
      export BASH_TEST_RUNNER_TEST_PATH=""
      path_initialized_here=true
    fi

    unset BASH_TEST_RUNNER_LOG_NESTED
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Top-level call, created new session: $session_dir" >&2
      echo "DEBUG: Initialized test counter to: $BASH_TEST_RUNNER_TEST_COUNTER" >&2
      echo "DEBUG: Initialized test path to: '${BASH_TEST_RUNNER_TEST_PATH}'" >&2
    fi
  fi

  log_file="${session_dir}/main.log"

  if [[ "$session_created_here" == true ]]; then
    touch "$log_file"
    tail -f -n +1 "$log_file" &
    tail_pid=$!
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Started tail -f on $log_file with PID $tail_pid" >&2
    fi
  fi

  # Call the core function
  bashTestRunner-executeAndReport-core "$test_functions_ref_name" "$ignored_tests_ref_name" "$run_id" "$testPwd" "$log_file" "$session_dir"
  local final_status=$?

  # Restore the nested flag if this was a nested call
  if [[ "$is_nested" == true ]]; then
    if [[ $nested_was_set -eq 1 ]]; then
      export BASH_TEST_RUNNER_LOG_NESTED="$saved_nested"
    else
      unset BASH_TEST_RUNNER_LOG_NESTED
    fi
  fi

  # Clean up environment variables if this was the top-level call
  if [[ "$session_created_here" == true ]]; then
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Top-level call finished, cleaning up session environment variable" >&2
    fi
    if [[ -n "$tail_pid" ]]; then
      kill $tail_pid 2>/dev/null || true
      if [[ -n "$DEBUG" ]]; then
        echo "DEBUG: Killed tail PID $tail_pid" >&2
      fi
    fi
    unset BASH_TEST_RUNNER_SESSION
    unset BASH_TEST_RUNNER_LOG_NESTED

    if [[ "$counter_initialized_here" == true ]]; then
      unset BASH_TEST_RUNNER_TEST_COUNTER
      if [[ -n "$DEBUG" ]]; then
        echo "DEBUG: Cleaned up test counter" >&2
      fi
    fi

    if [[ "$path_initialized_here" == true ]]; then
      unset BASH_TEST_RUNNER_TEST_PATH
      if [[ -n "$DEBUG" ]]; then
        echo "DEBUG: Cleaned up test path" >&2
      fi
    fi
  fi

  return $final_status
}
