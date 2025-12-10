#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
# Set locale for numeric operations globally to ensure consistent decimal handling
export LC_NUMERIC=C

bashTestRunner() {
    command -v markdown-show-help-registration &>/dev/null && eval "$(markdown-show-help-registration)"
  # Parse options and positionals
  local excludes=()
  local positionals=()
  local help_requested=false
  local find_failing_seeds=false
  local find_failing_seeds_limit=100
  local reproduce_seed=""

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
      -ff|--find-failing-seeds)
        find_failing_seeds=true
        shift
        ;;
      -ffl|--find-failing-seeds-limit)
        if [[ -z $2 ]] || ! [[ $2 =~ ^[0-9]+$ ]]; then
          echo "Error: --find-failing-seeds-limit requires a numeric argument" >&2
          return 1
        fi
        find_failing_seeds_limit=$2
        shift 2
        ;;
      -r|--reproduce)
        if [[ -z $2 ]]; then
          echo "Error: --reproduce requires a seed argument" >&2
          return 1
        fi
        reproduce_seed="$2"
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
    echo "  -x, --exclude <tests>              Additional tests to ignore (space-separated, quoted if multiple)"
    echo "  -ff, --find-failing-seeds          Hunt for seeds that cause test failures"
    echo "  -ffl, --find-failing-seeds-limit N Limit seed hunting to N attempts (default: 100)"
    echo "  -r, --reproduce <seed>             Reproduce a bug using a specific seed"
    echo "  -h, --help                         Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  BASH_TEST_RUNNER_SEED              Set specific seed for deterministic test shuffling"
    echo ""
    echo "Examples:"
    echo "  bashTestRunner myTests ignored                    # Normal test run"
    echo "  BASH_TEST_RUNNER_SEED=42 bashTestRunner myTests ignored  # Run with specific seed"
    echo "  bashTestRunner myTests ignored -ff               # Hunt for failing seeds"
    echo "  bashTestRunner myTests ignored -ff -ffl 50       # Hunt with 50 attempts max"
    echo "  bashTestRunner myTests ignored -r abc123         # Reproduce bug with seed abc123"
    return 0
  fi

  if [[ ${#positionals[@]} -ne 2 ]]; then
    echo "Error: Requires exactly two positional arguments: test_functions_array and ignored_tests_array" >&2
    return 1
  fi

  # Handle special modes
  if [[ "$find_failing_seeds" == true ]]; then
    bashTestRunner-findFailingSeeds "${positionals[0]}" "${positionals[1]}" "$find_failing_seeds_limit"
    return $?
  fi

  if [[ -n "$reproduce_seed" ]]; then
    bashTestRunner-reproduceBug "${positionals[0]}" "${positionals[1]}" "$reproduce_seed"
    return $?
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
