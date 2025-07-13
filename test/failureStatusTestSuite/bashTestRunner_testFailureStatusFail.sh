#!/usr/bin/env bash
bashTestRunner_testFailureStatusFail() {
  echo "Running a test that will deliberately fail"
  return 1
}