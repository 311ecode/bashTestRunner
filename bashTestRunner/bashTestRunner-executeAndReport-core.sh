#!/usr/bin/env bash
bashTestRunner-executeAndReport-core() {
  local test_functions_ref_name=$1
  local ignored_tests_ref_name=$2
  local run_id=$3
  local testPwd=$4
  local log_file=$5
  local session_dir=$6

  # Get array references for inputs
  local -n test_functions_ref=${test_functions_ref_name}
  local -n ignored_tests_ref=${ignored_tests_ref_name}

  echo "======================================" >> "${log_file}"
  echo "Starting test suite with ${#test_functions_ref[@]} tests" >> "${log_file}"
  echo "(Plus ${#ignored_tests_ref[@]} ignored tests)" >> "${log_file}"
  echo "======================================" >> "${log_file}"
  echo "" >> "${log_file}"

  # Execute all tests and collect results
  bashTestRunner-executeTests "${test_functions_ref_name}" "${ignored_tests_ref_name}" "$run_id" "$testPwd" "${log_file}" "${session_dir}"

  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: Metrics after execution for run_id=$run_id:" >&2
    eval "for key in \"\${!metrics_$run_id[@]}\"; do echo \"DEBUG:   \$key = \${metrics_$run_id[\$key]}\" >&2; done"
  fi

  # Call the summary function with all collected data
  bashTestRunner-printSummary "results_$run_id" "passing_ignored_tests_$run_id" "metrics_$run_id" "${test_functions_ref_name}" "suite_durations_$run_id" "${log_file}" "${session_dir}"

  # Get the final status BEFORE cleaning up arrays
  bashTestRunner-evaluateStatus "metrics_${run_id}"
  local final_status=$?

  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: bashTestRunner-executeAndReport final_status=$final_status for run_id=$run_id" >&2
    echo "DEBUG: Metrics at evaluation:" >&2
    local metric_var
    for metric_var in ignored_tests_count ignored_passed passed_tests failed_tests counted_tests total_duration ignored_failed; do
        eval "echo \"DEBUG:   ${metric_var} = \${metrics_${run_id}[${metric_var}]}\" >&2"
    done
  fi

  return $final_status
}