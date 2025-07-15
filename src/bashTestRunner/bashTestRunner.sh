#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Set locale for numeric operations globally to ensure consistent decimal handling
export LC_NUMERIC=C

bashTestRunner() {
  # Parse options and positionals
  local excludes=()
  local positionals=()
  local help_requested=false

  while [[ $# -gt 0 ]]; do
    case $1 in
      -x|--exclude)
        if [[ -z $2 ]]; then
          echo "Error: --exclude requires an argument" >&2
          return 1
        fi
        IFS=' ' read -r -a temp_excludes <<< "$2"
        excludes+=("${temp_excludes[@]}")
        shift 2
        ;;
      -h|--help)
        help_requested=true
        shift
        ;;
      -*)
        echo "Unknown option: $1" >&2
        return 1
        ;;
      *)
        positionals+=("$1")
        shift
        ;;
    esac
  done

  if $help_requested; then
    echo "Usage: bashTestRunner [options] <test_functions_array> <ignored_tests_array>"
    echo "Options:"
    echo "  -x, --exclude <tests>   Additional tests to ignore (space-separated, quoted if multiple)"
    echo "  -h, --help              Show this help message"
    return 0
  fi

  if [[ ${#positionals[@]} -ne 2 ]]; then
    echo "Error: Requires exactly two positional arguments: test_functions_array and ignored_tests_array" >&2
    return 1
  fi

  # Get array references for inputs
  local -n test_functions_ref=${positionals[0]}
  local -n ignored_tests_ref=${positionals[1]}
  local testPwd="$(pwd)"

  # Add excludes to ignored_tests_ref
  for exclude in "${excludes[@]}"; do
    ignored_tests_ref+=("$exclude")
  done

  # Generate a unique identifier for this test run
  local run_id=$(date +%s%N | sha256sum | head -c 8)

  # Call the execution and reporting function
  bashTestRunner-executeAndReport "${positionals[0]}" "${positionals[1]}" "$run_id" "$testPwd" "${excludes[@]}"
}

