# Implementation Guide: bashTestRunner Test Suites 🚀

## Overview 🌟

Welcome to the bashTestRunner framework! This guide helps you craft robust, fun-to-read test suites inspired by the ModelSelectionStrategy example. Create isolated, self-contained test files—no need to embed the full bashTestRunner code. Let's make testing exciting with emojis for vibes! 😎

## Core Concepts 🛠️

### What This Framework Provides

- **Automated Test Execution** 🤖: Discovers and runs tests automatically—no manual setup drama!
- **Environment Isolation** 🔒: Modify vars safely; everything restores like magic. No test cross-talk! ✨
- **Flexible Test Organization** 📂: Ignore tests or group them easily. Skip the boring ones! 🚫
- **On-Demand Execution** ⚡: Tests fire up when you run the script. Instant gratification!

## File Structure Template - Nested Test Runner Approach 📄

Here's your blueprint for a nested test suite. It gives **awesome error reporting** with paths like: `testYourFeature -> testBasicFunctionality -> assertion fail` ❌. Super helpful for debugging!

```bash
#!/usr/bin/env bash
# Copyright and licensing info here 📜

# @file yourTestFile.sh
# @brief Test suite description
# @description Comprehensive tests using bashTestRunner framework

# Main test suite function with nested structure 🎯
testYourFeature() {
  export LC_NUMERIC=C  # 🔢 Ensures consistent numbers—must-have!

  # Define individual test functions INSIDE the main runner 🧩
  testBasicFunctionality() {
    echo "🧪 Testing basic functionality"
    # Your test code here...
    return 0  # ✅ Success!
  }

  testErrorHandling() {
    echo "⚠️ Testing error conditions"
    # Simulate oops moments...
    return 0  # ✅ Handled!
  }

  testEnvironmentVariables() {
    echo "🌍 Testing env var handling"
    # Play with globals safely...
    return 0  # ✅ Restored!
  }

  testEdgeCases() {
    echo "🧨 Testing edge cases"
    # Push limits! 💥
    return 0  # ✅ Survived!
  }

  # Test function registry 📋
  local test_functions=(
    "testBasicFunctionality"
    "testErrorHandling"
    "testEnvironmentVariables"
    "testEdgeCases"
  )

  local ignored_tests=()  # 🚫 Add names to skip, e.g., "testEdgeCases"

  bashTestRunner test_functions ignored_tests
  return $?  # 🎉 Done!
}

# Execute if run directly 🚀
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  testYourFeature
fi
```

**Why Nested?** Better encapsulation, organization, and hierarchical error vibes! 📊

## Essential Requirements ⚠️

### LC_NUMERIC Setting 🔢

**Must-Do**: Set `LC_NUMERIC=C` for consistent numeric formatting. Avoid locale surprises! 😱

**Options**:
1. **Export for All** (Recommended for multi-ops):
   ```bash
   export LC_NUMERIC=C
   bashTestRunner test_functions ignored_tests
   ```
2. **One-Off**:
   ```bash
   LC_NUMERIC=C bashTestRunner test_functions ignored_tests
   ```

Both keep numbers reliable across systems. 🌐

## Step 1: Define Your Test Suite Structure 🏗️

Start with a main function listing your tests:

```bash
testYourFeature() {
  local test_functions=(
    "testFirstScenario"  # 🏁 Start here
    "testSecondScenario" # 📈 Build up
    "testErrorCondition" # 🚨 Handle fails
  )

  local ignored_tests=()  # 🚫 Skip if flaky

  bashTestRunner test_functions ignored_tests
  return $?  # 🎯 Exit status
}
```

## Step 2: Implement Individual Test Functions (Nested Style) 🔧

Define tests **inside** the main runner for epic error tracing! 📍

```bash
testYourFeature() {
  # Nested tests for better vibes 🧑‍🔬
  testFirstScenario() {
    echo "🧪 Testing basic functionality"

    # Save env state 🔒
    local saved_var="${IMPORTANT_VAR:-}"

    # Setup test env 🌍
    export IMPORTANT_VAR="test_value"

    # Run the thing! ⚙️
    local result=$(yourFunctionToTest "test input")

    # Restore like a pro ✨
    if [[ -n "$saved_var" ]]; then
      export IMPORTANT_VAR="$saved_var"
    else
      unset IMPORTANT_VAR
    fi

    # Assert! ✅
    if [[ "$result" == "expected_output" ]]; then
      echo "✅ SUCCESS: Test passed"
      return 0
    else
      echo "❌ ERROR: Expected 'expected_output', got '$result'"
      return 1
    fi
  }

  testSecondScenario() {
    echo "🔄 Testing another scenario"
    # More fun here...
    return 0  # ✅
  }

  # Registry at end 📋
  local test_functions=(
    "testFirstScenario"
    "testSecondScenario"
  )

  local ignored_tests=()

  # LC_NUMERIC vibes 🔢
  bashTestRunner test_functions ignored_tests

  return $?  # 🎉
}
```

**Nested Wins**: Clear paths like `testYourFeature -> testFirstScenario -> fail` for debugging joy! 🕵️‍♂️

## Step 3: Environment Management Best Practices 🛡️

**Save First**: Always backup vars before tweaks! 📥

```bash
local saved_strategies="${ModelSelectionStrategies:-}"
local saved_api_key="${API_KEY:-}"
```

**Restore Cleanly**: Use unset logic for pristine state! 🧹

```bash
if [[ -n "$saved_strategies" ]]; then
  export ModelSelectionStrategies="$saved_strategies"
else
  unset ModelSelectionStrategies
fi
```

**Temp Files**: Cleanup crew on duty! 🗑️

```bash
local temp_output=$(mktemp)
# Use it... 📝
rm -f "$temp_output"  # Gone!
```

## Step 4: Testing Different Scenarios 🎭

**Success Path** ✅:

```bash
testUserPreferenceStrategy() {
  echo "🧑‍💼 Testing user prefs"
  export USER_PREFERRED_MODEL="preferred:model"
  local result=$(selectModelWithStrategy "test prompt")

  if [[ "$result" == "preferred:model" ]]; then
    echo "✅ SUCCESS: Preference honored!"
    return 0
  fi
}
```

**Error Path** ⚠️:

```bash
testMissingDependency() {
  echo "🚫 Testing missing deps"
  unset REQUIRED_API_KEY

  local temp_output=$(mktemp)
  yourFunction "test" 2>"$temp_output" >/dev/null

  if grep -q "Expected error message" "$temp_output"; then
    echo "✅ SUCCESS: Error handled!"
    rm -f "$temp_output"
    return 0
  fi
}
```

**Fallback Chain** 🔄:

```bash
testStrategyFallback() {
  echo "🔄 Testing fallbacks"
  export STRATEGIES="primary,secondary,tertiary"
  unset PRIMARY_CONFIG  # Force fallback! 💥
  export SECONDARY_CONFIG="working"

  local result=$(executeWithFallback "input")
  # Verify secondary kicked in! 🦸
}
```

## Advanced Patterns 🚀

### Testing Strategy Chains 🔗

```bash
testComplexFallback() {
  echo "🔗 Testing chain fallbacks"
  export STRATEGY_CHAIN="strategy1,strategy2,strategy3"
  unset STRATEGY1_REQUIREMENT
  unset STRATEGY2_REQUIREMENT
  export STRATEGY3_REQUIREMENT="available"

  local result=$(executeStrategies "context")

  if [[ "$result" == "strategy3:output" ]]; then
    echo "✅ SUCCESS: Fallback chain works!"
    return 0
  fi
}
```

### Testing Availability Checks 🔍

```bash
testAvailabilityLogic() {
  echo "🔍 Testing resource checks"

  # Unavailable? ❌
  unset RESOURCE_KEY
  if isResourceAvailable "resource:name"; then
    echo "❌ ERROR: Should not be available!"
    return 1
  fi

  # Available? ✅
  export RESOURCE_KEY="test-key"
  if ! isResourceAvailable "resource:name"; then
    echo "❌ ERROR: Should be available!"
    return 1
  fi

  echo "✅ SUCCESS: Checks work!"
  return 0
}
```

## Framework Integration - Zero Configuration 🆓

bashTestRunner is **auto-magically available**! No sourcing, no PATH tweaks, no code embeds. Just call `bashTestRunner`—the system handles it. Clean and effortless! 🌈

## Test Function Requirements 📝

**Contract**:
- Return 0 for ✅ PASS
- Return 1 for ❌ FAIL
- Echo clear messages! 💬

```bash
testExample() {
  echo "🧪 Testing something specific"

  if [[ condition_met ]]; then
    echo "✅ SUCCESS: Test description"
    return 0
  else
    echo "❌ ERROR: Expected X, got Y"
    return 1
  fi
}
```

## Best Practices Summary ⭐

- **Isolation** 🔒: Tests independent—no side effects!
- **Descriptive Names** 📛: Explain what's tested.
- **Environment Safety** 🛡️: Save/restore vars always.
- **Clear Output** 💬: Expected vs actual + emojis! 🎉
- **Error Handling** ⚠️: Test success AND failure paths.
- **Documentation** 📖: Describe validations briefly.
- **Modular Design** 🧩: Group related, keep focused.

Build powerful suites with flair—happy testing! 🚀
