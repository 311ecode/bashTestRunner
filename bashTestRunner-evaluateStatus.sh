#!/bin/bash
bashTestRunner-evaluateStatus() {
  local -n metrics_ref=$1
  
  if [ "${metrics_ref[failed_tests]}" -gt 0 ]; then
    return 1
  else
    return 0
  fi
}