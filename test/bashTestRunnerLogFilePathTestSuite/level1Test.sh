#!/usr/bin/env bash
level1Test() {
    echo "Level 1 test calling level 2"
    local level2_functions=("level2Test")
    local level2_ignored=()
    bashTestRunner level2_functions level2_ignored
    return $?
  }