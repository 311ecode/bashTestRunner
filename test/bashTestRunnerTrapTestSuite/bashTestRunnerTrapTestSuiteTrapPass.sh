#!/usr/bin/env bash
bashTestRunnerTrapTestSuiteTrapPass() {
  local trapped=false
  
  # Set trap on ERR
  trap 'trapped="true"; echo "Unexpected error trapped"' ERR
  
  # Run a command that succeeds (no ERR)
  echo "Running succeeding command"
  true
  
  # Reset trap to avoid affecting other tests
  trap - ERR
  
  echo "Trap reset"
  
  # Verify trap didn't trigger
  if $trapped; then
    echo "ERROR: Trap triggered unexpectedly"
    return 1
  else
    echo "SUCCESS: No error, trap did not trigger as expected"
    return 0
  fi
}