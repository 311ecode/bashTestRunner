#!/usr/bin/env bash
bashTestRunner_testIgnoredFailureSuiteFail() {
  echo "Running a test that will deliberately fail (but is ignored)"
  return 1
}
