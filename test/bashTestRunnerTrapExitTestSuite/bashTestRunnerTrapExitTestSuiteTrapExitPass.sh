#!/usr/bin/env bash
bashTestRunnerTrapExitTestSuiteTrapExitPass() {
  # Set trap on EXIT
  trap 'echo "EXIT trapped successfully"' EXIT

  echo "Running passing test with EXIT trap"

  return 0
  # The trap will trigger after return, printing to output
}
