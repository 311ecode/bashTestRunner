#!/usr/bin/env bash
bashTestRunnerTrapTestSuiteTrapFail() {
  local trapped=false
  
  # Set trap on ERR
  trap 'trapped="true"; echo "Error trapped as expected"' ERR
  
  # Run a command that fails (triggers ERR)
  echo "Running failing command to trigger trap"
  false
  
  # Reset trap to avoid affecting other tests
  trap - ERR
  
  echo "Trap reset"
  
  # Verify trap triggered, but intentionally fail the test
  if $trapped; then
    echo "SUCCESS: Trap triggered, but failing test as per design"
    return 1  # Intentionally return failure
  else
    echo "ERROR: Trap did not trigger on error"
    return 1
  fi
}