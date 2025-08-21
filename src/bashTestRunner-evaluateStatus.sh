#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.
bashTestRunner-evaluateStatus() {
  local metrics_name=$1

  # Properly handle dynamic array name resolution
  local failed=0
  if eval "[[ -v ${metrics_name}[failed_tests] ]]" 2>/dev/null; then
    eval "failed=\${${metrics_name}[failed_tests]}"
  fi

  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: bashTestRunner-evaluateStatus called with metrics_name=$metrics_name" >&2
    echo "DEBUG: failed_tests value = '$failed'" >&2
    eval "echo \"DEBUG: All metrics for $metrics_name:\" >&2"
    eval "for key in \"\${!$metrics_name[@]}\"; do echo \"DEBUG:   \$key = \${$metrics_name[\$key]}\" >&2; done"
  fi

  if [[ "$failed" -gt 0 ]]; then
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Returning 1 (failure) because failed_tests=$failed > 0" >&2
    fi
    return 1
  else
    if [[ -n "$DEBUG" ]]; then
      echo "DEBUG: Returning 0 (success) because failed_tests=$failed = 0" >&2
    fi
    return 0
  fi
}
