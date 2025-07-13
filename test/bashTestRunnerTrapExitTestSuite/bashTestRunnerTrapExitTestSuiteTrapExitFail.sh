#!/usr/bin/env bash
bashTestRunnerTrapExitTestSuiteTrapExitFail() {
  # Set trap on EXIT
  trap 'echo "EXIT trapped on fail"' EXIT
  
  echo "Running failing test with EXIT trap"
  
  return 1
  # The trap will trigger after return, printing to output
}