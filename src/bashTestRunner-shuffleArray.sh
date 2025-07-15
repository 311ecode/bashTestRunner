#!/usr/bin/env bash
# Copyright © 2025 Imre Toth <tothimre@gmail.com> - Proprietary Software. See LICENSE file for terms.

bashTestRunner-shuffleArray() {
  local -n array_ref=$1
  local seed=$2
  
  if [[ -z "$seed" ]]; then
    # No seed provided, keep original order
    return 0
  fi
  
  # Convert seed to numeric value if it's not already
  local numeric_seed
  if [[ "$seed" =~ ^[0-9]+$ ]]; then
    numeric_seed=$seed
  else
    # Convert string to numeric seed using hash
    local hash=$(echo -n "$seed" | sha256sum | head -c 8)
    numeric_seed=$((0x$hash))
  fi
  
  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: Shuffling array with seed='$seed', numeric_seed='$numeric_seed'" >&2
    echo "DEBUG: Original order: ${array_ref[*]}" >&2
  fi
  
  # Fisher-Yates shuffle with deterministic random number generator
  local array_size=${#array_ref[@]}
  local i j temp
  local rng_state=$numeric_seed
  
  for ((i = array_size - 1; i > 0; i--)); do
    # Linear congruential generator for deterministic "random" numbers
    rng_state=$(( (rng_state * 1664525 + 1013904223) % (2**31) ))
    j=$(( rng_state % (i + 1) ))
    
    # Swap elements i and j
    temp="${array_ref[$i]}"
    array_ref[$i]="${array_ref[$j]}"
    array_ref[$j]="$temp"
  done
  
  if [[ -n "$DEBUG" ]]; then
    echo "DEBUG: Shuffled order: ${array_ref[*]}" >&2
  fi
}