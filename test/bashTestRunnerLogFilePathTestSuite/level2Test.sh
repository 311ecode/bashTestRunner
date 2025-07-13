#!/usr/bin/env bash
level2Test() {
    echo "Level 2 test calling level 3"
    local level3_functions=("level3Test")
    local level3_ignored=()
    bashTestRunner level3_functions level3_ignored
    return $?
  }